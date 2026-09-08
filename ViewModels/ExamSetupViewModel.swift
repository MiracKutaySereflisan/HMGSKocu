import Foundation
import Combine

@MainActor
final class ExamSetupViewModel: ObservableObject {
    enum ScopeKind: String, CaseIterable, Identifiable {
        case full = "Tüm HMGS Müfredatı"
        case bySubject = "Ders Bazlı Seçim"
        var id: String { rawValue }

        var detail: String {
            switch self {
            case .full: return "Sorular gerçek HMGS ders dağılımına göre çekilir."
            case .bySubject: return "İstediğin dersleri seç, sadece onlardan çöz."
            }
        }

        var icon: String {
            switch self {
            case .full: return "square.stack.3d.up.fill"
            case .bySubject: return "checklist"
            }
        }
    }

    @Published var scopeKind: ScopeKind = .full { didSet { refreshAvailableCount() } }
    @Published var selectedSubjects: Set<LegalSubject> = [] { didSet { refreshAvailableCount() } }
    @Published var questionCount: Int = 20
    @Published var timeMode: TimeMode = .hmgsStandard
    /// Bu kapsamda şu an kaç soru var. nil = henüz bilinmiyor. Sınav BAŞLAMADAN
    /// önce uyarabilmek için — kullanıcı ince havuzu sınav başladıktan sonra
    /// keşfetmesin.
    @Published private(set) var availableQuestionCount: Int?

    let questionCountRange = 5...120
    let questionCountStep = 5
    private let store = AppDataStore.shared
    private var refreshTask: Task<Void, Never>?

    var selectedSubjectsOrdered: [LegalSubject] {
        LegalSubject.displayOrdered.filter { selectedSubjects.contains($0) }
    }

    func refreshAvailableCount() {
        refreshTask?.cancel()
        let subjects: [LegalSubject]?
        switch scopeKind {
        case .full: subjects = nil
        case .bySubject: subjects = Array(selectedSubjects)
        }

        if scopeKind == .bySubject, selectedSubjects.isEmpty {
            availableQuestionCount = 0
            return
        }

        refreshTask = Task { [weak self] in
            guard let self else { return }
            let count = try? await self.store.fetchQuestions(subjects: subjects).count
            guard !Task.isCancelled else { return }
            self.availableQuestionCount = count
        }
    }

    func toggle(_ subject: LegalSubject) {
        if selectedSubjects.contains(subject) {
            selectedSubjects.remove(subject)
        } else {
            selectedSubjects.insert(subject)
        }
    }

    func selectAllSubjects() {
        selectedSubjects = Set(LegalSubject.allCases)
    }

    func clearSubjects() {
        selectedSubjects = []
    }

    var resolvedScope: ExamScope {
        switch scopeKind {
        case .full: return .fullHMGS
        case .bySubject:
            if selectedSubjects.count == 1, let only = selectedSubjects.first {
                return .singleSubject(only)
            }
            return .customMix(selectedSubjectsOrdered)
        }
    }

    /// Havuzda istenenden az soru varsa sınavı var olan soru sayısıyla başlat —
    /// "40 soru istedim, 12 geldi" sürprizini kullanıcı zaten uyarı metninden biliyor.
    var effectiveQuestionCount: Int {
        guard let available = availableQuestionCount, available > 0 else { return questionCount }
        return min(questionCount, available)
    }

    func makeConfiguration() -> ExamConfiguration {
        ExamConfiguration(
            scope: resolvedScope,
            questionCount: effectiveQuestionCount,
            timeMode: timeMode
        )
    }

    var timeLimitPreviewText: String {
        guard timeMode == .hmgsStandard else {
            return "Süre sınırı yok — bitirdiğinde geçen süre kaydedilir."
        }
        let seconds = Int((Double(effectiveQuestionCount) * Question.secondsPerQuestion).rounded())
        let minutes = max(1, seconds / 60)
        return "Süre: \(minutes) dakika (gerçek HMGS temposu: 120 soru / 155 dakika)"
    }

    var canStart: Bool {
        guard (availableQuestionCount ?? 1) > 0 else { return false }
        switch scopeKind {
        case .full: return true
        case .bySubject: return !selectedSubjects.isEmpty
        }
    }

    /// "Soru Adedi" altında görünen açıklama. nil = sayı hâlâ yükleniyor.
    var poolSizeText: String? {
        guard let available = availableQuestionCount else { return nil }
        if available == 0 {
            return scopeKind == .bySubject && selectedSubjects.isEmpty
                ? "Başlamak için en az bir ders seç."
                : "Bu seçimde henüz soru yok."
        }
        if available < questionCount {
            return "Bu seçimde \(available) soru var — sınav \(available) soruyla başlayacak."
        }
        return "Bu seçimde \(available) soru mevcut."
    }

    var poolWarningIsActive: Bool {
        guard let available = availableQuestionCount else { return false }
        return available < questionCount
    }

    func increaseCount() {
        questionCount = min(questionCountRange.upperBound, questionCount + questionCountStep)
    }

    func decreaseCount() {
        questionCount = max(questionCountRange.lowerBound, questionCount - questionCountStep)
    }
}
