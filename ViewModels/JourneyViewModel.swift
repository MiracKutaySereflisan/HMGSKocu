// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import Foundation
import Combine

/// Yolculuk'un durumunu tutar: ders başına türetilmiş aşama yolu, açık/kapalı/geçildi
/// durumu, XP ve seviye. Diğer ViewModel'larla aynı kural — yalnızca `AppDataStore`
/// ile konuşur, asla `LocalStore` ile doğrudan.
@MainActor
final class JourneyViewModel: ObservableObject {
    @Published private(set) var progress = JourneyProgress()
    @Published private(set) var allQuestions: [Question] = []
    @Published private(set) var layout = JourneyStageLayout()
    @Published private(set) var isLoading = true
    @Published var errorMessage: String?

    private let store = AppDataStore.shared
    /// Aşama listesi her karede yeniden hesaplanmasın diye küçük bir önbellek —
    /// ders çubuğunda 24 ders var ve her biri için `stages(for:)` çağrılıyor.
    private var stageCache: [LegalSubject: [Stage]] = [:]

    var levelInfo: (level: Int, xpIntoLevel: Int, xpForLevel: Int) {
        XPEngine.progress(forTotalXP: progress.totalXP)
    }

    var totalCompletedStages: Int { progress.totalCompletedStageCount }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let questions = try await store.fetchQuestions()
            let savedProgress = try await store.fetchJourneyProgress()
            let previousLayout = try await store.fetchJourneyStageLayout()

            allQuestions = questions
            progress = savedProgress

            // Yeni eklenen sorular mevcut aşamalara dokunmadan sona ekleniyor;
            // kimsenin geçmiş ilerlemesi bozulmuyor. Bkz. JourneyCatalogue.reconcile.
            let reconciled = JourneyCatalogue.reconcile(layout: previousLayout, pool: questions)
            layout = reconciled
            stageCache = [:]
            if reconciled != previousLayout {
                try await store.saveJourneyStageLayout(reconciled)
            }
        } catch {
            errorMessage = ActiveExamViewModel.message(for: error)
        }
    }

    func stages(for subject: LegalSubject) -> [Stage] {
        if let cached = stageCache[subject] { return cached }
        let built = JourneyCatalogue.stages(for: subject, layout: layout, pool: allQuestions)
        stageCache[subject] = built
        return built
    }

    func clearedCount(for subject: LegalSubject) -> Int {
        stages(for: subject).filter(progress.isCompleted).count
    }

    func isUnlocked(_ stage: Stage) -> Bool { progress.isUnlocked(stage) }
    func isCompleted(_ stage: Stage) -> Bool { progress.isCompleted(stage) }

    /// Kullanıcının o derste şu an bulunduğu (açık ama geçilmemiş) ilk aşama.
    func currentStage(for subject: LegalSubject) -> Stage? {
        stages(for: subject).first { isUnlocked($0) && !isCompleted($0) }
    }

    func configuration(for stage: Stage) -> ExamConfiguration {
        ExamConfiguration(
            scope: .journeyStage(subject: stage.subject, stageIndex: stage.index),
            questionCount: stage.questionIDs.count,
            timeMode: .untimed
        )
    }

    /// Bir Yolculuk aşaması bittikten sonra çağrılır: XP verir, ilk geçişte aşamayı
    /// tamamlanmış işaretler, ilerlemeyi kaydeder ve sonuç ekranının kutlama
    /// gösterebilmesi için ne olduğunu döner.
    ///
    /// Aynı oturum için iki kez çağrılırsa (sonuç ekranı yeniden çizilirse) ikinci
    /// çağrı XP vermez — `recordedSessionIDs` bunu garantiliyor.
    private var recordedSessionIDs: Set<UUID> = []

    @discardableResult
    func recordStageResult(for session: ExamSession) async -> XPEngine.StageResult? {
        guard case .journeyStage(let subject, let stageIndex) = session.scope else { return nil }
        guard !recordedSessionIDs.contains(session.id) else { return nil }
        guard let stage = stages(for: subject).first(where: { $0.index == stageIndex }) else { return nil }
        recordedSessionIDs.insert(session.id)

        let wasAlreadyCompleted = progress.isCompleted(stage)
        let result = XPEngine.evaluate(session: session, wasAlreadyCompleted: wasAlreadyCompleted)

        progress.totalXP += result.xpEarned
        if result.passed { progress.markCompleted(stage) }

        do {
            try await store.saveJourneyProgress(progress)
        } catch {
            errorMessage = ActiveExamViewModel.message(for: error)
        }
        return result
    }
}
