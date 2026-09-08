// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import Foundation
import Combine

/// Diskle konuşan tek yer. `actor` olması sayesinde tüm dosya okuma/yazma işleri
/// ana iş parçacığının DIŞINDA ve birbirine karışmadan (aynı anda iki yazma yok)
/// çalışıyor — arayüz hiçbir zaman disk yüzünden donmuyor.
actor PersistenceActor {
    static let shared = PersistenceActor()

    func sessions() throws -> [ExamSession] { try LocalStore.loadSessions() }
    func append(session: ExamSession) throws { try LocalStore.append(session) }

    func stats() throws -> [QuestionStat] { try LocalStore.loadStats() }
    func upsert(stats: [QuestionStat]) throws { try LocalStore.upsertStats(stats) }

    func journeyProgress() throws -> JourneyProgress { try LocalStore.loadJourneyProgress() }
    func save(journeyProgress: JourneyProgress) throws { try LocalStore.saveJourneyProgress(journeyProgress) }

    func journeyLayout() throws -> JourneyStageLayout { try LocalStore.loadJourneyStageLayout() }
    func save(journeyLayout: JourneyStageLayout) throws { try LocalStore.saveJourneyStageLayout(journeyLayout) }

    func achievements() throws -> [Achievement] { try LocalStore.loadUnlockedAchievements() }
    func save(achievements: [Achievement]) throws { try LocalStore.saveUnlockedAchievements(achievements) }

    func inProgressExam() throws -> InProgressExam? { try LocalStore.loadInProgressExam() }
    func save(inProgressExam: InProgressExam) throws { try LocalStore.saveInProgressExam(inProgressExam) }
    func clearInProgressExam() { LocalStore.clearInProgressExam() }

    func deleteAllData() { LocalStore.deleteAllData() }

    /// Soru havuzu değişmediği için bir kez okunup bellekte tutuluyor: 680 soruluk
    /// JSON'u her ekran açılışında yeniden çözümlemek boşuna iş ve gözle görülür gecikme.
    private var cachedQuestions: [Question]?

    func allQuestions() throws -> [Question] {
        if let cachedQuestions { return cachedQuestions }
        let loaded = try SeedQuestionLoader.loadAll()
        cachedQuestions = loaded
        return loaded
    }
}

/// Arayüzün (ViewModel'ların) konuştuğu tek servis. ViewModel'lar asla `LocalStore`
/// ya da `PersistenceActor` ile doğrudan konuşmaz — böylece ileride veri katmanı
/// değişirse (iCloud senkronu, sunucu, başka bir veritabanı) tek dosya değişir.
@MainActor
final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    /// Kullanıcının kendine verdiği ad. Cihazdan çıkmaz, kimseye gönderilmez —
    /// yalnızca ana sayfada "Günaydın, Mirac" diyebilmek için.
    @Published private(set) var displayName: String
    @Published private(set) var hasProfile: Bool
    /// Son kaydetme hatası — arayüz bunu bir kez gösterip temizler.
    @Published var lastErrorMessage: String?

    private let persistence = PersistenceActor.shared

    private init() {
        let saved = UserDefaults.standard.string(forKey: DefaultsKey.displayName)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        displayName = saved.isEmpty ? "Hukukçu" : saved
        hasProfile = !saved.isEmpty
    }

    // MARK: - Profil

    static let maxNameLength = 24

    /// İsmi kaydeder. Boş bırakılırsa nazik bir varsayılana düşer; aşırı uzun
    /// isimler arayüzü bozmasın diye kırpılır.
    func setDisplayName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = trimmed.isEmpty ? "Hukukçu" : String(trimmed.prefix(Self.maxNameLength))
        displayName = cleaned
        hasProfile = true
        UserDefaults.standard.set(cleaned, forKey: DefaultsKey.displayName)
    }

    // MARK: - Sorular

    func fetchQuestions(subjects: [LegalSubject]? = nil) async throws -> [Question] {
        let all = try await persistence.allQuestions()
        guard let subjects, !subjects.isEmpty else { return all }
        let wanted = Set(subjects)
        return all.filter { wanted.contains($0.subject) }
    }

    func fetchQuestions(byIDs ids: [UUID]) async throws -> [Question] {
        let all = try await persistence.allQuestions()
        let wanted = Set(ids)
        return all.filter { wanted.contains($0.id) }
    }

    // MARK: - Oturumlar

    func saveExamSession(_ session: ExamSession) async throws {
        try await persistence.append(session: session)
        recordStudyDay(session.startedAt)
    }

    func fetchSessions() async throws -> [ExamSession] {
        try await persistence.sessions()
    }

    // MARK: - İstatistikler / hata havuzu

    func upsertQuestionStats(_ stats: [QuestionStat]) async throws {
        try await persistence.upsert(stats: stats)
    }

    func fetchQuestionStats() async throws -> [QuestionStat] {
        try await persistence.stats()
    }

    // MARK: - Yolculuk

    func saveJourneyProgress(_ progress: JourneyProgress) async throws {
        try await persistence.save(journeyProgress: progress)
    }

    func fetchJourneyProgress() async throws -> JourneyProgress {
        try await persistence.journeyProgress()
    }

    func saveJourneyStageLayout(_ layout: JourneyStageLayout) async throws {
        try await persistence.save(journeyLayout: layout)
    }

    func fetchJourneyStageLayout() async throws -> JourneyStageLayout {
        try await persistence.journeyLayout()
    }

    // MARK: - Başarımlar

    func saveUnlockedAchievements(_ achievements: [Achievement]) async throws {
        try await persistence.save(achievements: achievements)
    }

    func fetchUnlockedAchievements() async throws -> [Achievement] {
        try await persistence.achievements()
    }

    // MARK: - Yarım kalan sınav

    func saveInProgressExam(_ exam: InProgressExam) async {
        do {
            try await persistence.save(inProgressExam: exam)
        } catch {
            // Yarım sınav kaydı kullanıcıyı rahatsız edecek kadar kritik değil —
            // sınav zaten bellekte devam ediyor ve bir sonraki cevapta yeniden
            // denenecek. Yine de sessizce yutmuyoruz: teknik günlüğe düşüyor.
            AppLog.persistenceIssue("in_progress_exam kaydı", error)
        }
    }

    func fetchInProgressExam() async -> InProgressExam? {
        do {
            guard let exam = try await persistence.inProgressExam() else { return nil }
            // Çok eski bir yarım sınavı teklif etmek yardımcı olmaz, kafa karıştırır.
            return exam.isStillOfferable ? exam : nil
        } catch {
            AppLog.persistenceIssue("in_progress_exam okuma", error)
            return nil
        }
    }

    func clearInProgressExam() async {
        await persistence.clearInProgressExam()
    }

    // MARK: - Çalışma günleri (seri takibi)

    /// Hangi günlerde soru çözüldüğünü tutar — "Yedi Gün Üst Üste" başarımı ve
    /// ana sayfadaki seri göstergesi için. Sadece gün damgası; saat/konum yok.
    private func recordStudyDay(_ date: Date) {
        let stamp = Self.dayStamp(date)
        var stamps = UserDefaults.standard.stringArray(forKey: DefaultsKey.studyDayStamps) ?? []
        guard !stamps.contains(stamp) else { return }
        stamps.append(stamp)
        // Seri hesabı için son 400 gün fazlasıyla yeter.
        if stamps.count > 400 { stamps = Array(stamps.suffix(400)) }
        UserDefaults.standard.set(stamps, forKey: DefaultsKey.studyDayStamps)
    }

    var studyDayStamps: [String] {
        UserDefaults.standard.stringArray(forKey: DefaultsKey.studyDayStamps) ?? []
    }

    /// Bugün ya da dün ile biten kesintisiz çalışma serisi.
    var currentStreak: Int {
        StreakCalculator.streak(from: studyDayStamps, today: Date())
    }

    static func dayStamp(_ date: Date) -> String {
        StreakCalculator.formatter.string(from: date)
    }

    // MARK: - Verilerimi sil

    func deleteAllData() async {
        await persistence.deleteAllData()
        displayName = "Hukukçu"
        hasProfile = false
    }
}

/// Seri (streak) hesabı — saf fonksiyon olduğu için test edilebiliyor.
enum StreakCalculator {
    /// Tek örnek olarak tutuluyor: her çağrıda yeni formatter üretmek, 400 güne
    /// kadar döngü dönen seri hesabında gereksiz maliyet olurdu. Oluşturulduktan
    /// sonra hiç DEĞİŞTİRİLMİYOR, yalnızca `string(from:)` ile okunuyor.
    ///
    /// Not: iOS 26 SDK'sında `DateFormatter` artık `Sendable`; bu yüzden
    /// `nonisolated(unsafe)` gerekmiyor (Xcode uyarı veriyordu) ve kaldırıldı.
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")   // gün damgası dile göre değişmesin
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Bugünden (ya da dünden) geriye doğru kesintisiz gün sayısı.
    /// Bugün çözülmemişse ama dün çözülmüşse seri hâlâ ayakta sayılır — kullanıcı
    /// günü henüz bitirmedi.
    static func streak(from stamps: [String], today: Date) -> Int {
        let set = Set(stamps)
        guard !set.isEmpty else { return 0 }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current

        var cursor = calendar.startOfDay(for: today)
        if !set.contains(formatter.string(from: cursor)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
                  set.contains(formatter.string(from: yesterday)) else { return 0 }
            cursor = yesterday
        }

        var count = 0
        while set.contains(formatter.string(from: cursor)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }
}
