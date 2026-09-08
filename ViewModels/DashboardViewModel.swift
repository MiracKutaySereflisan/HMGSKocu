import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var recentSessions: [ExamSession] = []
    @Published private(set) var allSessions: [ExamSession] = []
    @Published private(set) var subjectProgress: [SubjectProgress] = []
    @Published private(set) var todaySolvedCount: Int = 0
    @Published private(set) var todayCorrectRate: Double = 0
    @Published private(set) var streak: Int = 0
    @Published private(set) var mistakePoolCount: Int = 0
    /// Yarım kalmış bir sınav varsa ana sayfada "Kaldığın yerden devam et" kartı çıkar.
    @Published private(set) var resumableExam: InProgressExam?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    @Published var dailyGoal: Int = DailyGoal.normalized(
        UserDefaults.standard.integer(forKey: DefaultsKey.dailyGoal)
    )

    private let store = AppDataStore.shared

    var goalRatio: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1, Double(todaySolvedCount) / Double(dailyGoal))
    }

    func setDailyGoal(_ goal: Int) {
        let normalized = DailyGoal.normalized(goal)
        dailyGoal = normalized
        UserDefaults.standard.set(normalized, forKey: DefaultsKey.dailyGoal)
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let sessions = try await store.fetchSessions()
            allSessions = sessions.sorted { $0.startedAt > $1.startedAt }
            recentSessions = Array(allSessions.filter { !$0.scope.isRetakeScope }.prefix(8))

            let stats = try await store.fetchQuestionStats()
            subjectProgress = SubjectProgressAggregator.aggregate(stats: stats)
            mistakePoolCount = stats.filter(\.isInMistakePool).count

            let calendar = Calendar.current
            let todaysAnswers = sessions
                .filter { calendar.isDateInToday($0.startedAt) }
                .flatMap(\.answers)
            todaySolvedCount = todaysAnswers.filter { $0.selectedOptionIndex != nil }.count
            let todayCorrect = todaysAnswers.filter { $0.isCorrect == true }.count
            todayCorrectRate = todaysAnswers.isEmpty ? 0 : Double(todayCorrect) / Double(todaysAnswers.count)

            streak = store.currentStreak
            resumableExam = await store.fetchInProgressExam()
        } catch {
            errorMessage = ActiveExamViewModel.message(for: error)
        }
    }

    func discardResumableExam() async {
        await store.clearInProgressExam()
        resumableExam = nil
    }

    /// Yarım kalan sınavı sürdürmek için gereken yapılandırma.
    func resumeConfiguration(for exam: InProgressExam) -> ExamConfiguration {
        ExamConfiguration(
            scope: exam.scope,
            questionCount: exam.questionIDs.count,
            timeMode: exam.timeMode
        )
    }
}
