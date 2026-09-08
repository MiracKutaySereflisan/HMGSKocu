import Foundation
import Combine

@MainActor
final class MistakePoolViewModel: ObservableObject {
    @Published private(set) var subjectCounts: [SubjectProgress] = []
    @Published private(set) var totalMistakes: Int = 0
    /// Ayrı bölüm: sınav erken bitirildiğinde boş kalan sorular. Yanlış yapılmış
    /// değiller ama yine de tekrar sorulmaları gerekiyor.
    @Published private(set) var blankSubjectCounts: [SubjectProgress] = []
    @Published private(set) var totalBlanks: Int = 0
    /// "Kazanılan Sorular" — yanlıştan doğruya çevrilen soru sayısı.
    @Published private(set) var totalReclaimed: Int = 0
    @Published private(set) var reclaimedSubjectCounts: [SubjectProgress] = []
    @Published private(set) var isLoading = true
    @Published var errorMessage: String?

    private let store = AppDataStore.shared
    private var wrongOnlyStats: [QuestionStat] = []
    private var blankOnlyStats: [QuestionStat] = []

    var isEmpty: Bool { totalMistakes == 0 && totalBlanks == 0 }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let stats = try await store.fetchQuestionStats()
            let mistakeStats = stats.filter(\.isInMistakePool)
            wrongOnlyStats = mistakeStats.filter { !$0.wasLastAttemptBlank }
            blankOnlyStats = mistakeStats.filter(\.wasLastAttemptBlank)
            totalMistakes = wrongOnlyStats.count
            totalBlanks = blankOnlyStats.count

            subjectCounts = Self.counts(from: wrongOnlyStats)
            blankSubjectCounts = Self.counts(from: blankOnlyStats)

            let reclaimedStats = stats.filter { $0.reclaimedCount > 0 }
            totalReclaimed = reclaimedStats.reduce(0) { $0 + $1.reclaimedCount }
            let reclaimedGrouped = Dictionary(grouping: reclaimedStats, by: \.subject)
            reclaimedSubjectCounts = LegalSubject.displayOrdered
                .compactMap { subject in
                    let total = (reclaimedGrouped[subject] ?? []).reduce(0) { $0 + $1.reclaimedCount }
                    guard total > 0 else { return nil }
                    return SubjectProgress(subject: subject, solved: total, correct: total, wrong: 0)
                }
                .sorted { $0.correct > $1.correct }
        } catch {
            errorMessage = ActiveExamViewModel.message(for: error)
        }
    }

    /// Ders başına soru sayısı — hem "Yanlış Yaptıkların" hem "Boş Bıraktıkların"
    /// bölümü aynı şekli kullanıyor.
    private static func counts(from stats: [QuestionStat]) -> [SubjectProgress] {
        let grouped = Dictionary(grouping: stats, by: \.subject)
        return LegalSubject.displayOrdered
            .compactMap { subject -> SubjectProgress? in
                let count = (grouped[subject] ?? []).count
                guard count > 0 else { return nil }
                return SubjectProgress(subject: subject, solved: count, correct: 0, wrong: count)
            }
            .sorted { $0.wrong > $1.wrong }
    }

    // MARK: - Tekrar çözme

    /// Hata havuzundan tekrar çözülecek sorular. Havuz o ders için boşsa nil döner —
    /// çağıran taraf 0 soruluk bir sınav başlatmasın.
    func retakePlan(subject: LegalSubject?, kind: RetakeKind) -> (configuration: ExamConfiguration, ids: [UUID])? {
        let source = kind == .wrong ? wrongOnlyStats : blankOnlyStats
        let relevant = subject == nil ? source : source.filter { $0.subject == subject }
        guard !relevant.isEmpty else { return nil }

        // En çok yanlış yapılan sorular önce gelsin — en zayıf halka önce çalışılsın.
        let ordered = relevant.sorted { lhs, rhs in
            if lhs.wrong != rhs.wrong { return lhs.wrong > rhs.wrong }
            return lhs.lastAttemptDate < rhs.lastAttemptDate
        }
        let ids = ordered.map(\.questionID)
        let scope: ExamScope = kind == .wrong ? .mistakePool(subject) : .blankPool(subject)
        let configuration = ExamConfiguration(scope: scope, questionCount: ids.count, timeMode: .untimed)
        return (configuration, ids)
    }

    enum RetakeKind { case wrong, blank }
}
