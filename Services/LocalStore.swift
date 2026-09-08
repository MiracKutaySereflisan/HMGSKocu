// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import Foundation

/// Diske JSON yazan basit kalıcılık katmanı. Uygulama tamamen çevrimdışı çalışır;
/// hiçbir veri cihazdan çıkmaz.
///
/// Dosyalar `Documents` klasöründe tutuluyor. Bu bilinçli bir tercih: Documents
/// iCloud yedeğine dahildir, yani kullanıcı telefon değiştirip yedekten dönerse
/// ilerlemesi geri gelir — bunun için hesap açtırmaya, sunucu tutmaya gerek yok.
enum LocalStore {

    /// Kalıcılık sırasında oluşan, kullanıcıya anlamlı bir cümleyle anlatılabilen hatalar.
    enum StoreError: LocalizedError {
        case writeFailed(file: String, underlying: Error)
        case readFailed(file: String, underlying: Error)

        var errorDescription: String? {
            switch self {
            case .writeFailed:
                return "İlerlemen kaydedilemedi. Cihazında yer kalmamış olabilir; yer açıp tekrar dene."
            case .readFailed:
                return "Kayıtlı ilerlemen okunamadı. Uygulamayı kapatıp açmayı dene."
            }
        }

        /// Kullanıcının yapabileceği bir şey var mı?
        ///
        /// Yazma hatasında var: yer açmak işe yarar, söylemek doğru. Okuma hatasında
        /// yok: "uygulamayı kapatıp aç" demek sorunu çözmüyor, sadece kutlama anını
        /// bozuyor. Okuma hataları artık kurtarmalı okumayla (bkz. `readArray`)
        /// zaten neredeyse imkânsız; kalanı sessizce günlüğe düşüyor.
        var isUserActionable: Bool {
            switch self {
            case .writeFailed: return true
            case .readFailed: return false
            }
        }

        /// Geliştirici günlüğü için — kişisel veri içermez, yalnızca dosya adı.
        var debugSummary: String {
            switch self {
            case .writeFailed(let file, let underlying): return "write \(file): \(underlying)"
            case .readFailed(let file, let underlying): return "read \(file): \(underlying)"
            }
        }
    }

    private enum File: String, CaseIterable {
        case sessions = "exam_sessions.json"
        case stats = "question_stats.json"
        case journeyProgress = "journey_progress.json"
        case journeyLayout = "journey_stage_layout.json"
        case achievements = "unlocked_achievements.json"
        case inProgressExam = "in_progress_exam.json"
    }

    private static var directory: URL {
        // `.documentDirectory` her zaman en az bir sonuç döner; yine de zorlama açma
        // kullanmamak için güvenli düşüş yolu var.
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return url
        }
        return URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    private static func url(_ file: File) -> URL {
        directory.appendingPathComponent(file.rawValue)
    }

    // MARK: - Sınav oturumları

    /// En fazla bu kadar oturum saklanır. Sınırsız büyüyen bir dosya, iki yıl
    /// kullanan birinde her açılışta megabaytlarca JSON çözümlemesi demek olurdu.
    static let maxStoredSessions = 500

    static func append(_ session: ExamSession) throws {
        var all = try loadSessions()
        all.removeAll { $0.id == session.id }
        all.append(session)
        if all.count > maxStoredSessions {
            all = Array(all.sorted { $0.startedAt > $1.startedAt }.prefix(maxStoredSessions))
        }
        try write(all, to: .sessions)
    }

    static func loadSessions() throws -> [ExamSession] {
        try readArray(ExamSession.self, from: .sessions)
    }

    // MARK: - Soru istatistikleri

    /// Tek tek `upsert` yerine toplu yazım: bir sınavda 120 soru varsa eski kod
    /// dosyayı 120 kez okuyup 120 kez yazıyordu (O(n²) disk trafiği). Bu sürüm
    /// tek okuma + tek yazım yapıyor.
    static func upsertStats(_ stats: [QuestionStat]) throws {
        guard !stats.isEmpty else { return }
        var all = try loadStats()
        var indexByID: [UUID: Int] = [:]
        for (index, stat) in all.enumerated() { indexByID[stat.questionID] = index }

        for stat in stats {
            if let index = indexByID[stat.questionID] {
                all[index] = stat
            } else {
                indexByID[stat.questionID] = all.count
                all.append(stat)
            }
        }
        try write(all, to: .stats)
    }

    static func loadStats() throws -> [QuestionStat] {
        try readArray(QuestionStat.self, from: .stats)
    }

    // MARK: - Yolculuk

    static func saveJourneyProgress(_ progress: JourneyProgress) throws {
        try write(progress, to: .journeyProgress)
    }

    static func loadJourneyProgress() throws -> JourneyProgress {
        try read(JourneyProgress.self, from: .journeyProgress) ?? JourneyProgress()
    }

    static func saveJourneyStageLayout(_ layout: JourneyStageLayout) throws {
        try write(layout, to: .journeyLayout)
    }

    static func loadJourneyStageLayout() throws -> JourneyStageLayout {
        try read(JourneyStageLayout.self, from: .journeyLayout) ?? JourneyStageLayout()
    }

    // MARK: - Başarımlar

    static func saveUnlockedAchievements(_ achievements: [Achievement]) throws {
        try write(achievements, to: .achievements)
    }

    static func loadUnlockedAchievements() throws -> [Achievement] {
        try readArray(Achievement.self, from: .achievements)
    }

    // MARK: - Yarım kalan sınav

    static func saveInProgressExam(_ exam: InProgressExam) throws {
        try write(exam, to: .inProgressExam)
    }

    static func loadInProgressExam() throws -> InProgressExam? {
        try read(InProgressExam.self, from: .inProgressExam)
    }

    static func clearInProgressExam() {
        // Silinemezse yapacak bir şey yok ve kullanıcıya söylenecek bir şey de yok;
        // bir sonraki kaydetme üzerine yazar.
        try? FileManager.default.removeItem(at: url(.inProgressExam))
    }

    // MARK: - Tüm verileri sil (Profil > Verilerimi Sil)

    /// Kullanıcının uygulamadaki her şeyini siler. Geri alınamaz; çağıran taraf
    /// mutlaka onay almalı.
    static func deleteAllData() {
        for file in File.allCases {
            try? FileManager.default.removeItem(at: url(file))
        }
        for key in DefaultsKey.all {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: - Yardımcılar

    private static func write<T: Encodable>(_ value: T, to file: File) throws {
        let target = url(file)
        do {
            let data = try JSONEncoder.hmgs.encode(value)
            // .atomic: yazma sırasında uygulama öldürülürse yarım dosya kalmaz,
            // eski dosya olduğu gibi durur.
            try data.write(to: target, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            throw StoreError.writeFailed(file: file.rawValue, underlying: error)
        }
    }

    /// Tek bir bozuk kayıt, dosyanın TAMAMINI okunamaz hale getirmemeli.
    ///
    /// Gerçek hata bu yüzden yazıldı: eski bir sürümde kaydedilmiş tek bir
    /// istatistik satırı yüzünden `question_stats.json` hiç okunamıyor, kullanıcı
    /// her sınav sonunda "Kayıtlı ilerlemen okunamadı" uyarısı alıyordu — üstelik
    /// uygulamayı kapatıp açmak da işe yaramıyordu, çünkü dosya kalıcı olarak
    /// okunamaz durumdaydı.
    ///
    /// Yeni davranış: önce olağan yol denenir (hiçbir şey bozuk değilse tek geçiş,
    /// ek maliyet yok). Bozuk kayıt varsa okunabilenler kurtarılır, bozuklar atılır
    /// ve dosya bir kez temiz hâliyle geri yazılır — böylece ayıklama her açılışta
    /// tekrarlanmaz.
    private static func readArray<T: Codable>(_ type: T.Type, from file: File) throws -> [T] {
        let source = url(file)
        guard FileManager.default.fileExists(atPath: source.path) else { return [] }

        let data: Data
        do {
            data = try Data(contentsOf: source)
        } catch {
            throw StoreError.readFailed(file: file.rawValue, underlying: error)
        }
        guard !data.isEmpty else { return [] }

        if let clean = try? JSONDecoder.hmgs.decode([T].self, from: data) { return clean }

        let salvaged: [Lenient<T>]
        do {
            salvaged = try JSONDecoder.hmgs.decode([Lenient<T>].self, from: data)
        } catch {
            // Yalnızca dosyanın kendisi (dizi yapısı) bozuksa buraya düşülür.
            throw StoreError.readFailed(file: file.rawValue, underlying: error)
        }

        let kept = salvaged.compactMap(\.value)
        AppLog.recordsDropped(file: file.rawValue, dropped: salvaged.count - kept.count, kept: kept.count)
        try? write(kept, to: file)
        return kept
    }

    /// Okunamayan öğeyi hataya çevirmek yerine `nil` yapan sarmalayıcı.
    private struct Lenient<T: Decodable>: Decodable {
        let value: T?
        init(from decoder: Decoder) throws {
            value = try? T(from: decoder)
        }
    }

    private static func read<T: Decodable>(_ type: T.Type, from file: File) throws -> T? {
        let source = url(file)
        guard FileManager.default.fileExists(atPath: source.path) else { return nil }
        do {
            let data = try Data(contentsOf: source)
            guard !data.isEmpty else { return nil }
            return try JSONDecoder.hmgs.decode(T.self, from: data)
        } catch {
            throw StoreError.readFailed(file: file.rawValue, underlying: error)
        }
    }
}

// Not: bunlar bilinçli olarak `static let` (paylaşılan tek örnek) DEĞİL,
// her erişimde yeni örnek üreten `static var`. Sebebi: JSONEncoder/JSONDecoder
// `Sendable` değil; paylaşılan tek örnek, farklı iş parçacıklarından aynı anda
// kullanıldığında sessiz veri bozulmasına açık olurdu. Örnek oluşturmanın
// maliyeti, saniyede bir kez bile çağrılmayan bu yollarda ölçülemeyecek kadar az.
extension JSONEncoder {
    static var hmgs: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var hmgs: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
