import Foundation
import Combine

@MainActor
final class ActiveExamViewModel: ObservableObject {

    /// Ekranın içinde bulunduğu hâl. Eski kodda bu üç ayrı bool ile temsil ediliyordu
    /// (isLoading / errorMessage / finishedSession) ve "yükleme bitti ama soru da yok"
    /// gibi bir durumda ekran bomboş kalıyordu. Tek bir enum olunca her hâl
    /// arayüzde karşılığı olmak zorunda.
    enum Phase: Equatable {
        case loading
        case running
        case empty(reason: String)
        case failed(message: String)
        case finished
    }

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var questions: [Question] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var answers: [UUID: Int] = [:]
    /// Her soruda gerçekten geçirilen süre — sorudan ayrılırken toplanıyor
    /// (`flushCurrentQuestionTime`). Tek bir "ilk görülme" damgasından türetilseydi
    /// kullanıcı geri dönüp baktığında süreler üst üste binerdi.
    @Published private(set) var questionElapsedSeconds: [UUID: Double] = [:]
    @Published private(set) var timer: TimerEngine?
    @Published private(set) var finishedSession: ExamSession?
    @Published private(set) var newlyUnlockedAchievements: [Achievement] = []
    /// İstenen sayıda soru bulunamadıysa kaç soruyla başlandığı.
    @Published private(set) var startedWithFewerThanRequested = false
    @Published private(set) var availableQuestionCount = 0
    /// Kaydetme başarısız olduysa kullanıcıya gösterilecek uyarı (sonuç yine gösterilir).
    @Published var saveWarning: String?

    let configuration: ExamConfiguration
    private var startedAt = Date()
    private let store = AppDataStore.shared
    private let explicitQuestionIDs: [UUID]?
    private let resuming: InProgressExam?

    private var currentQuestionEnteredAt: Date?
    /// Süre dolması ile kullanıcının "Bitir"e basması aynı ana denk gelirse sınav
    /// iki kez kaydedilip XP iki kez verilebiliyordu. Bu bayrak onu engelliyor.
    private var isFinishing = false
    private var autosaveTask: Task<Void, Never>?

    init(
        configuration: ExamConfiguration,
        explicitQuestionIDs: [UUID]? = nil,
        resuming: InProgressExam? = nil
    ) {
        self.configuration = configuration
        self.explicitQuestionIDs = explicitQuestionIDs
        self.resuming = resuming
    }

    var currentQuestion: Question? {
        questions.indices.contains(currentIndex) ? questions[currentIndex] : nil
    }

    var answeredCount: Int { answers.count }

    var isLastQuestion: Bool { currentIndex == questions.count - 1 }

    var progressRatio: Double {
        questions.isEmpty ? 0 : Double(currentIndex + 1) / Double(questions.count)
    }

    // MARK: - Yükleme

    func load() async {
        guard case .loading = phase else { return }   // ekran yeniden görünürse baştan yüklemesin
        do {
            let pool = try await resolvePool()
            availableQuestionCount = pool.count

            guard !pool.isEmpty else {
                phase = .empty(reason: emptyReason)
                return
            }

            if let resuming {
                // Sürdürülen sınav: soru sırası kayıtla AYNI olmalı, yoksa
                // "3. sorudaydım" bambaşka bir soruya işaret eder.
                var byID: [UUID: Question] = [:]
                for question in pool { byID[question.id] = question }
                questions = resuming.questionIDs.compactMap { byID[$0] }
                answers = resuming.answers
                questionElapsedSeconds = resuming.questionElapsedSeconds
                currentIndex = min(max(0, resuming.currentIndex), max(0, questions.count - 1))
                startedAt = resuming.startedAt
                startedWithFewerThanRequested = false
            } else {
                questions = Array(pool.prefix(configuration.questionCount))
                startedWithFewerThanRequested = pool.count < configuration.questionCount
                startedAt = Date()
            }

            guard !questions.isEmpty else {
                phase = .empty(reason: emptyReason)
                return
            }

            currentQuestionEnteredAt = Date()
            let engine = TimerEngine(
                mode: configuration.timeMode,
                limitSeconds: configuration.timeLimitSeconds,
                alreadyElapsedSeconds: resuming?.elapsedSeconds ?? 0
            )
            engine.onTimeExpired = { [weak self] in
                Task { @MainActor in await self?.finish(reason: .timeExpired) }
            }
            timer = engine
            engine.start()
            phase = .running
            persistProgress()
        } catch {
            phase = .failed(message: Self.message(for: error))
        }
    }

    private func resolvePool() async throws -> [Question] {
        if let explicitQuestionIDs {
            let fetched = try await store.fetchQuestions(byIDs: explicitQuestionIDs)
            // Havuzdan gelen sırayı koru (ID listesi zaten anlamlı bir sırada).
            var byID: [UUID: Question] = [:]
            for question in fetched { byID[question.id] = question }
            return explicitQuestionIDs.compactMap { byID[$0] }
        }
        if let resuming {
            return try await store.fetchQuestions(byIDs: resuming.questionIDs)
        }

        let subjects: [LegalSubject]?
        switch configuration.scope {
        case .fullHMGS: subjects = nil
        case .singleSubject(let subject): subjects = [subject]
        case .customMix(let list): subjects = list
        case .mistakePool, .blankPool: subjects = nil
        case .journeyStage(let subject, _): subjects = [subject]
        }

        let pool = try await store.fetchQuestions(subjects: subjects)
        let stats = try await store.fetchQuestionStats()
        if configuration.scope.comparesToHMGSThreshold {
            return QuestionSelector.weightedFullCurriculum(
                pool: pool, stats: stats, targetCount: configuration.questionCount
            )
        }
        return QuestionSelector.prioritized(pool: pool, stats: stats)
    }

    private var emptyReason: String {
        switch configuration.scope {
        case .mistakePool:
            return "Hata havuzunda tekrar çözülecek soru kalmamış. Yeni bir deneme çözünce yanlışların burada birikir."
        case .blankPool:
            return "Boş bıraktığın soru kalmamış."
        case .journeyStage:
            return "Bu aşamanın soruları bulunamadı. Uygulamayı güncellemek sorunu çözebilir."
        default:
            return "Bu seçimde şu an soru yok. Farklı bir ders seçmeyi dene."
        }
    }

    // MARK: - Kullanıcı etkileşimi

    func select(optionIndex: Int) {
        guard case .running = phase, let question = currentQuestion else { return }
        guard question.options.indices.contains(optionIndex) else { return }
        answers[question.id] = optionIndex
        persistProgress()
    }

    /// Seçili şıkkı geri alma — yanlışlıkla dokunulduğunda soruyu boş bırakabilmek
    /// için. (Sınavda "cevabı silmek" gerçek bir ihtiyaç.)
    func clearSelection() {
        guard case .running = phase, let question = currentQuestion else { return }
        answers.removeValue(forKey: question.id)
        persistProgress()
    }

    func goNext() {
        guard currentIndex < questions.count - 1 else { return }
        flushCurrentQuestionTime()
        currentIndex += 1
        currentQuestionEnteredAt = Date()
        persistProgress()
    }

    func goPrevious() {
        guard currentIndex > 0 else { return }
        flushCurrentQuestionTime()
        currentIndex -= 1
        currentQuestionEnteredAt = Date()
        persistProgress()
    }

    func jump(to index: Int) {
        guard questions.indices.contains(index), index != currentIndex else { return }
        flushCurrentQuestionTime()
        currentIndex = index
        currentQuestionEnteredAt = Date()
        persistProgress()
    }

    private func flushCurrentQuestionTime() {
        guard let question = currentQuestion, let enteredAt = currentQuestionEnteredAt else { return }
        let delta = max(0, Date().timeIntervalSince(enteredAt))
        questionElapsedSeconds[question.id, default: 0] += delta
        currentQuestionEnteredAt = Date()
    }

    // MARK: - Arka plan / ön plan

    func handleScenePhaseChange(isActive: Bool) {
        guard case .running = phase else { return }
        if isActive {
            currentQuestionEnteredAt = Date()
            timer?.start()
        } else {
            flushCurrentQuestionTime()
            timer?.pause()
            persistProgress()
        }
    }

    /// Yarım kalan sınavı diske yazar. Ekran her etkileşimde çağırıyor; yazma işi
    /// arka planda ve sıraya girerek yapıldığı için arayüzü yavaşlatmıyor.
    private func persistProgress() {
        guard case .running = phase, !isFinishing, !questions.isEmpty else { return }
        let snapshot = InProgressExam(
            scope: configuration.scope,
            timeMode: configuration.timeMode,
            timeLimitSeconds: configuration.timeLimitSeconds,
            questionIDs: questions.map(\.id),
            answers: answers,
            questionElapsedSeconds: questionElapsedSeconds,
            currentIndex: currentIndex,
            elapsedSeconds: timer?.elapsedSeconds ?? 0,
            startedAt: startedAt,
            savedAt: Date()
        )
        autosaveTask?.cancel()
        autosaveTask = Task { [store] in
            await store.saveInProgressExam(snapshot)
        }
    }

    // MARK: - Bitirme

    enum FinishReason { case userRequested, timeExpired }

    func finish(reason: FinishReason = .userRequested) async {
        guard !isFinishing, case .running = phase else { return }
        isFinishing = true

        flushCurrentQuestionTime()
        let elapsed = timer?.stop() ?? Date().timeIntervalSince(startedAt)
        autosaveTask?.cancel()
        await store.clearInProgressExam()

        let records: [AnswerRecord] = questions.map { question in
            let selected = answers[question.id]
            let isCorrect = selected.map { $0 == question.correctOptionIndex }
            return AnswerRecord(
                questionID: question.id,
                selectedOptionIndex: selected,
                isCorrect: isCorrect,
                timeSpentSeconds: questionElapsedSeconds[question.id] ?? 0
            )
        }

        let session = ExamSession(
            id: UUID(),
            scope: configuration.scope,
            startedAt: startedAt,
            finishedAt: Date(),
            answers: records,
            timeMode: configuration.timeMode,
            timeLimitSeconds: configuration.timeLimitSeconds,
            measuredElapsedSeconds: elapsed
        )

        do {
            try await store.saveExamSession(session)
            try await updateStatsAndMistakePool(for: session)
            try await evaluateAchievements(for: session)
        } catch {
            // Sonuç ekranı yine de gösteriliyor — kullanıcı emeğinin karşılığını görmeli.
            //
            // Uyarıyı yalnızca kullanıcının YAPABİLECEĞİ bir şey varsa göster.
            // Yazma hatasında var (yer aç, tekrar dene). Okuma hatasında yok:
            // "uygulamayı kapatıp aç" demek çözüm değil, sadece kutlama ekranını
            // bozuyor — kullanıcı da haklı olarak uygulamayı bozuk sanıyor.
            if let storeError = error as? LocalStore.StoreError, !storeError.isUserActionable {
                AppLog.persistenceIssue("sınav sonrası istatistik/başarım", error)
            } else {
                saveWarning = Self.message(for: error)
            }
        }

        finishedSession = session
        phase = .finished
        if reason == .timeExpired { Haptics.warning() }
    }

    private func updateStatsAndMistakePool(for session: ExamSession) async throws {
        var byID: [UUID: Question] = [:]
        for question in questions { byID[question.id] = question }

        var existing: [UUID: QuestionStat] = [:]
        for stat in try await store.fetchQuestionStats() { existing[stat.questionID] = stat }

        let now = Date()
        var updated: [QuestionStat] = []
        updated.reserveCapacity(session.answers.count)

        for answer in session.answers {
            guard let question = byID[answer.questionID] else { continue }
            var stat = existing[answer.questionID] ?? QuestionStat(
                questionID: answer.questionID,
                subject: question.subject,
                attempts: 0, correct: 0, wrong: 0,
                lastAttemptDate: now,
                isInMistakePool: false
            )
            stat.lastAttemptDate = now

            switch answer.isCorrect {
            case true:
                if stat.isInMistakePool {
                    // Havuzdayken doğru yapıldı — "kazanılan soru".
                    stat.reclaimedCount += 1
                }
                stat.attempts += 1
                stat.correct += 1
                stat.isInMistakePool = false
                stat.wasLastAttemptBlank = false
            case false:
                stat.attempts += 1
                stat.wrong += 1
                stat.isInMistakePool = true
                stat.wasLastAttemptBlank = false
            case nil:
                // Boş bırakılan soru yanlış SAYILMAZ (doğruluk oranını düşürmez) ama
                // tekrar karşına çıkması için havuza girer.
                stat.blank += 1
                stat.isInMistakePool = true
                stat.wasLastAttemptBlank = true
            }
            updated.append(stat)
        }

        try await store.upsertQuestionStats(updated)
    }

    private func evaluateAchievements(for session: ExamSession) async throws {
        let allSessions = try await store.fetchSessions()
        let stats = try await store.fetchQuestionStats()
        let journeyProgress = try await store.fetchJourneyProgress()

        let input = AchievementEngine.Input(
            finishedSession: session,
            allSessions: allSessions,
            subjectProgress: SubjectProgressAggregator.aggregate(stats: stats),
            mistakePoolRemaining: stats.filter(\.isInMistakePool).count,
            everInMistakePoolCount: stats.filter { $0.wrong > 0 || $0.blank > 0 }.count,
            journeyCompletedStageCount: journeyProgress.totalCompletedStageCount,
            currentStreak: store.currentStreak,
            alreadyUnlocked: Set(try await store.fetchUnlockedAchievements().map(\.id))
        )

        let newly = AchievementEngine.evaluate(input)
        guard !newly.isEmpty else { return }
        newlyUnlockedAchievements = newly
        let existing = try await store.fetchUnlockedAchievements()
        try await store.saveUnlockedAchievements(existing + newly)
    }

    // MARK: - Yardımcı

    static func message(for error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return "Beklenmedik bir sorun oluştu. Uygulamayı kapatıp açmayı dene."
    }
}

/// Ders bazlı toplamı hem Ana Sayfa hem Profil hem de başarım motoru kullanıyor —
/// tek yerde durması için ViewModel'dan çıkarıldı.
enum SubjectProgressAggregator {
    static func aggregate(stats: [QuestionStat]) -> [SubjectProgress] {
        let grouped = Dictionary(grouping: stats, by: \.subject)
        return LegalSubject.displayOrdered.map { subject in
            let group = grouped[subject] ?? []
            return SubjectProgress(
                subject: subject,
                solved: group.reduce(0) { $0 + $1.attempts },
                correct: group.reduce(0) { $0 + $1.correct },
                wrong: group.reduce(0) { $0 + $1.wrong }
            )
        }
    }
}
