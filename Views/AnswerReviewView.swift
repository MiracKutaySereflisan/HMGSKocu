import SwiftUI

/// Sınav bitince "Soruları İncele" ile açılan ekran. Hatadan öğrenme adımı burası:
/// her soruda ne işaretlendiği, doğrusunun ne olduğu, gerekçesi ve dayandığı madde.
struct AnswerReviewView: View {
    let session: ExamSession
    let questions: [Question]

    enum Filter: String, CaseIterable, Identifiable {
        case all = "Tümü"
        case wrong = "Yanlış"
        case blank = "Boş"
        var id: String { rawValue }
    }

    @State private var filter: Filter = .all

    private var answerByQuestionID: [UUID: AnswerRecord] {
        var map: [UUID: AnswerRecord] = [:]
        for answer in session.answers { map[answer.questionID] = answer }
        return map
    }

    private var orderedQuestions: [Question] {
        let answers = answerByQuestionID
        let answered = questions.filter { answers[$0.id] != nil }
        switch filter {
        case .all:
            return answered
        case .wrong:
            return answered.filter { answers[$0.id]?.isCorrect == false }
        case .blank:
            return answered.filter { answers[$0.id]?.selectedOptionIndex == nil }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: HMGSTheme.Layout.sectionSpacing) {
                Picker("Filtre", selection: $filter) {
                    ForEach(Filter.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                if orderedQuestions.isEmpty {
                    ContentUnavailableView {
                        Label(emptyTitle, systemImage: "checkmark.circle")
                    } description: {
                        Text(emptyMessage)
                    }
                    .padding(.top, 30)
                } else {
                    ForEach(Array(orderedQuestions.enumerated()), id: \.element.id) { index, question in
                        if let record = answerByQuestionID[question.id] {
                            ReviewQuestionCard(index: index + 1, question: question, record: record)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Soruları İncele")
        .navigationBarTitleDisplayMode(.inline)
        .background(HMGSTheme.Colors.background)
    }

    private var emptyTitle: String {
        switch filter {
        case .all: return "Gösterilecek soru yok"
        case .wrong: return "Hiç yanlışın yok"
        case .blank: return "Hiç boş bırakmamışsın"
        }
    }

    private var emptyMessage: String {
        switch filter {
        case .all: return "Bu denemede kayıtlı soru bulunamadı."
        case .wrong: return "Bu denemedeki soruların hepsini doğru ya da boş yaptın."
        case .blank: return "Bu denemede tüm soruları cevapladın."
        }
    }
}

private struct ReviewQuestionCard: View {
    let index: Int
    let question: Question
    let record: AnswerRecord

    private var statusColor: Color {
        switch record.isCorrect {
        case true: return HMGSTheme.Colors.success
        case false: return HMGSTheme.Colors.destructive
        case nil: return HMGSTheme.Colors.secondaryLabel
        }
    }

    private var statusLabel: String {
        switch record.isCorrect {
        case true: return "Doğru"
        case false: return "Yanlış"
        case nil: return "Boş"
        }
    }

    private var statusIcon: String {
        switch record.isCorrect {
        case true: return "checkmark.circle.fill"
        case false: return "xmark.circle.fill"
        case nil: return "minus.circle.fill"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Soru \(index)")
                    .font(.subheadline.bold())
                    .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                Spacer()
                // Durum hem SİMGE hem METİN hem renkle veriliyor: renk körlüğü olan
                // kullanıcı da doğru/yanlış ayrımını görebiliyor.
                Label(statusLabel, systemImage: statusIcon)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(statusColor)
            }

            Text(question.prompt)
                .hmgsQuestionTextStyle()

            VStack(spacing: 8) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { idx, text in
                    optionLine(idx: idx, text: text)
                }
            }

            if !question.explanation.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(question.explanation)
                        .font(.footnote)
                        .foregroundStyle(HMGSTheme.Colors.label)
                        .fixedSize(horizontal: false, vertical: true)
                    if let reference = question.lawReference, !reference.isEmpty {
                        Text(reference)
                            .font(HMGSTheme.Typography.lawReference)
                            .foregroundStyle(HMGSTheme.Colors.accent)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HMGSTheme.Colors.tertiaryBackground, in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.controlCornerRadius, style: .continuous))
            }

            if let url = FeedbackComposer.reportQuestionURL(question: question) {
                Link(destination: url) {
                    Label("Bu soruda hata var", systemImage: "flag")
                        .font(.caption)
                        .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                }
            }
        }
        .hmgsCard()
    }

    @ViewBuilder
    private func optionLine(idx: Int, text: String) -> some View {
        let isCorrectOption = idx == question.correctOptionIndex
        let isUserPick = idx == record.selectedOptionIndex

        HStack(alignment: .top, spacing: 8) {
            Image(systemName: iconName(isCorrectOption: isCorrectOption, isUserPick: isUserPick))
                .foregroundStyle(iconColor(isCorrectOption: isCorrectOption, isUserPick: isUserPick))
                .frame(width: 18)
            Text("\(Question.optionLetter(idx))) \(text)")
                .font(HMGSTheme.Typography.optionText)
                .foregroundStyle(isCorrectOption || isUserPick ? HMGSTheme.Colors.label : HMGSTheme.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(idx: idx, text: text, isCorrectOption: isCorrectOption, isUserPick: isUserPick))
    }

    private func accessibilityLabel(idx: Int, text: String, isCorrectOption: Bool, isUserPick: Bool) -> String {
        var parts = ["\(Question.optionLetter(idx)) şıkkı: \(text)"]
        if isCorrectOption { parts.append("doğru cevap") }
        if isUserPick && !isCorrectOption { parts.append("senin işaretlediğin") }
        return parts.joined(separator: ", ")
    }

    private func iconName(isCorrectOption: Bool, isUserPick: Bool) -> String {
        if isCorrectOption { return "checkmark.circle.fill" }
        if isUserPick { return "xmark.circle.fill" }
        return "circle"
    }

    private func iconColor(isCorrectOption: Bool, isUserPick: Bool) -> Color {
        if isCorrectOption { return HMGSTheme.Colors.success }
        if isUserPick { return HMGSTheme.Colors.destructive }
        return HMGSTheme.Colors.secondaryLabel.opacity(0.4)
    }
}
