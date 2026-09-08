import SwiftUI

struct ExamResultView: View {
    let session: ExamSession
    let achievements: [Achievement]
    var questions: [Question] = []
    var saveWarning: String?
    /// Yalnızca Yolculuk oturumlarında dolu — XP/seviye bloğunu sürüyor.
    var journeyViewModel: JourneyViewModel?

    @State private var showReview = false
    @State private var stageResult: XPEngine.StageResult?
    @State private var didLevelUp = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: HMGSTheme.Layout.sectionSpacing) {
                if let saveWarning {
                    warningBanner(saveWarning)
                }
                scoreCard
                if session.scope.comparesToHMGSThreshold {
                    thresholdBanner
                }
                if journeyViewModel != nil, case .journeyStage = session.scope, let stageResult {
                    journeyResultCard(stageResult)
                }
                if !achievements.isEmpty {
                    achievementsSection
                }
                subjectBreakdown
                actionButtons
            }
            .padding()
        }
        .hmgsAmbientBackground()
        .navigationTitle("Sonuçlar")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $showReview) {
            AnswerReviewView(session: session, questions: questions)
        }
        .task { await recordJourneyResultIfNeeded() }
    }

    private func recordJourneyResultIfNeeded() async {
        guard let journeyViewModel, stageResult == nil, case .journeyStage = session.scope else { return }
        let levelBefore = XPEngine.level(forTotalXP: journeyViewModel.progress.totalXP)
        let result = await journeyViewModel.recordStageResult(for: session)
        let levelAfter = XPEngine.level(forTotalXP: journeyViewModel.progress.totalXP)
        stageResult = result
        didLevelUp = levelAfter > levelBefore
        if result?.passed == true { Haptics.success() }
    }

    // MARK: - Puan kartı

    private var scoreCard: some View {
        VStack(spacing: 14) {
            Text(session.scope.label)
                .font(.headline)
                .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)

            ZStack {
                Circle()
                    .stroke(HMGSTheme.Colors.tertiaryBackground, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: min(1, session.scoreOutOf100 / 100))
                    .stroke(
                        LinearGradient(
                            colors: [HMGSTheme.Colors.accent, HMGSTheme.Colors.accent.opacity(0.6)],
                            startPoint: .topTrailing, endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(Int(session.scoreOutOf100.rounded()))")
                        // .system(size:) yerine ölçeklenen stil: en büyük yazı
                        // kademesinde de taşmıyor.
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("/ 100")
                        .font(.caption)
                        .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                }
                .padding(20)
            }
            .frame(width: 140, height: 140)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Puan: 100 üzerinden \(Int(session.scoreOutOf100.rounded()))")

            Text("\(session.correctCount) / \(session.totalCount) doğru")
                .font(.title3.weight(.semibold))

            HStack(spacing: 24) {
                statPill("Doğru", session.correctCount, HMGSTheme.Colors.success)
                statPill("Yanlış", session.wrongCount, HMGSTheme.Colors.destructive)
                statPill("Boş", session.blankCount, HMGSTheme.Colors.secondaryLabel)
            }

            Divider()

            HStack(spacing: 20) {
                metric(icon: "clock", title: "Süre", value: Format.duration(session.elapsedSeconds))
                if session.totalCount > 0 {
                    metric(
                        icon: "timer",
                        title: "Soru başına",
                        value: Format.duration(session.elapsedSeconds / Double(session.totalCount))
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .hmgsCard()
    }

    private func statPill(_ label: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.title3.bold()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(HMGSTheme.Colors.secondaryLabel)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func metric(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Label(value, systemImage: icon)
                .font(.subheadline.weight(.semibold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    private var thresholdBanner: some View {
        let passed = session.passesHMGSThreshold
        let color = passed ? HMGSTheme.Colors.success : HMGSTheme.Colors.warning
        return HStack(spacing: 10) {
            Image(systemName: passed ? "checkmark.seal.fill" : "target")
            Text(passed
                 ? "HMGS barajını (100 üzerinden 70) geçtin."
                 : "HMGS barajının (100 üzerinden 70) altında kaldın.")
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(color)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.controlCornerRadius, style: .continuous))
    }

    private func warningBanner(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundStyle(HMGSTheme.Colors.warning)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HMGSTheme.Colors.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.controlCornerRadius, style: .continuous))
    }

    // MARK: - Yolculuk sonucu

    private func journeyResultCard(_ result: XPEngine.StageResult) -> some View {
        VStack(spacing: 12) {
            MascotView(mood: result.passed ? .celebrating : .idle, size: 84)

            Text(result.passed
                 ? "Aşamayı geçtin — Kukuk seninle gurur duyuyor."
                 : "Bu aşama için %70 doğru gerekiyor. Kukuk yanında, tekrar dene.")
                .font(.headline)
                .foregroundStyle(result.passed ? HMGSTheme.Colors.success : HMGSTheme.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Label("+\(result.xpEarned) XP", systemImage: "bolt.fill")
                .font(.title3.bold())
                .foregroundStyle(HMGSTheme.Colors.warning)

            if didLevelUp, let journeyViewModel {
                Text("Seviye \(journeyViewModel.levelInfo.level)'e yükseldin.")
                    .font(.subheadline.bold())
                    .foregroundStyle(HMGSTheme.Colors.accent)
            } else if result.wasFirstClear {
                Text("Yolun bir sonraki aşaması açıldı.")
                    .font(.caption)
                    .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .hmgsCard()
    }

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HMGSSectionLabel("Yeni Başarımlar")
            ForEach(achievements) { achievement in
                HStack(spacing: 10) {
                    Image(systemName: "rosette")
                        .foregroundStyle(HMGSTheme.Colors.warning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(achievement.title).font(.subheadline.bold())
                        Text(achievement.detail)
                            .font(.caption)
                            .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .hmgsCard()
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// Hangi derste ne kadar doğru yaptığın — "nereye çalışayım" sorusunun
    /// cevabı sonuç ekranından çıkmalı, kullanıcı Profil'e gitmek zorunda kalmasın.
    @ViewBuilder
    private var subjectBreakdown: some View {
        let rows = Self.breakdown(session: session, questions: questions)
        if rows.count > 1 {
            VStack(alignment: .leading, spacing: 10) {
                HMGSSectionLabel("Ders Dağılımı")
                VStack(spacing: 8) {
                    ForEach(rows, id: \.subject) { row in
                        HStack(spacing: 10) {
                            Image(systemName: row.subject.journeyIcon)
                                .font(.caption)
                                .foregroundStyle(HMGSTheme.Colors.accent)
                                .frame(width: 20)
                            Text(row.subject.displayName)
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            Text("\(row.correct)/\(row.total)")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(row.correct == row.total ? HMGSTheme.Colors.success : HMGSTheme.Colors.label)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(HMGSTheme.Colors.cardBackground, in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.controlCornerRadius, style: .continuous))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(row.subject.displayName): \(row.total) soruda \(row.correct) doğru")
                    }
                }
            }
        }
    }

    struct BreakdownRow {
        let subject: LegalSubject
        let correct: Int
        let total: Int
    }

    static func breakdown(session: ExamSession, questions: [Question]) -> [BreakdownRow] {
        guard !questions.isEmpty else { return [] }
        var subjectByQuestion: [UUID: LegalSubject] = [:]
        for question in questions { subjectByQuestion[question.id] = question.subject }

        var totals: [LegalSubject: (correct: Int, total: Int)] = [:]
        for answer in session.answers {
            guard let subject = subjectByQuestion[answer.questionID] else { continue }
            var entry = totals[subject] ?? (0, 0)
            entry.total += 1
            if answer.isCorrect == true { entry.correct += 1 }
            totals[subject] = entry
        }
        return LegalSubject.displayOrdered.compactMap { subject in
            guard let entry = totals[subject], entry.total > 0 else { return nil }
            return BreakdownRow(subject: subject, correct: entry.correct, total: entry.total)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if !questions.isEmpty {
                Button {
                    showReview = true
                } label: {
                    Label("Soruları İncele", systemImage: "list.bullet.rectangle.portrait")
                }
                .buttonStyle(HMGSSecondaryButtonStyle())
            }

            Button {
                dismiss()
            } label: {
                Text("Bitir ve Çık")
            }
            .buttonStyle(HMGSPrimaryButtonStyle())
        }
    }
}
