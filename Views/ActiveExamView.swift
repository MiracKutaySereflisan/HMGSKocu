import SwiftUI

struct ActiveExamView: View {
    @StateObject var viewModel: ActiveExamViewModel
    /// Yalnızca Yolculuk'tan başlatılan oturumlarda dolu — sonuç ekranının XP verip
    /// seviye kutlaması yapabilmesi için aynı örneği paylaşıyor.
    var journeyViewModel: JourneyViewModel?

    @State private var showFinishConfirm = false
    @State private var showQuestionGrid = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        content
            .background(HMGSTheme.Colors.background)
            .task { await viewModel.load() }
            // Başlık yalnızca sınav sürerken buradan veriliyor. Sonuç ekranı kendi
            // başlığını koyuyor; ikisi birden başlık verirse hangisinin kazandığı
            // SwiftUI'da garanti değil ve başlık boş kalabiliyor.
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(isExamRunning)
            .toolbar { toolbarContent }
            .onChange(of: scenePhase) { _, newPhase in
                viewModel.handleScenePhaseChange(isActive: newPhase == .active)
            }
            .confirmationDialog(
                finishDialogTitle,
                isPresented: $showFinishConfirm,
                titleVisibility: .visible
            ) {
                Button("Sınavı Bitir", role: .destructive) { Task { await viewModel.finish() } }
                Button("Devam Et", role: .cancel) {}
            } message: {
                Text(finishDialogMessage)
            }
            .sheet(isPresented: $showQuestionGrid) {
                QuestionGridSheet(viewModel: viewModel)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .loading:
            ProgressView("Sorular hazırlanıyor…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .running:
            if let question = viewModel.currentQuestion {
                examBody(question: question)
                    .navigationTitle(viewModel.configuration.scope.label)
            } else {
                // Teoride ulaşılamaz; yine de boş ekran yerine bir çıkış yolu.
                emptyState(reason: "Soru yüklenemedi.")
            }

        case .empty(let reason):
            emptyState(reason: reason)

        case .failed(let message):
            ContentUnavailableView {
                Label("Sınav başlatılamadı", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Geri Dön") { dismiss() }
                    .buttonStyle(HMGSSecondaryButtonStyle())
                    .padding(.horizontal, 40)
            }

        case .finished:
            if let session = viewModel.finishedSession {
                ExamResultView(
                    session: session,
                    achievements: viewModel.newlyUnlockedAchievements,
                    questions: viewModel.questions,
                    saveWarning: viewModel.saveWarning,
                    journeyViewModel: journeyViewModel
                )
            }
        }
    }

    private func emptyState(reason: String) -> some View {
        ContentUnavailableView {
            Label("Çözülecek soru yok", systemImage: "tray")
        } description: {
            Text(reason)
        } actions: {
            Button("Geri Dön") { dismiss() }
                .buttonStyle(HMGSSecondaryButtonStyle())
                .padding(.horizontal, 40)
        }
    }

    private var isExamRunning: Bool {
        if case .running = viewModel.phase { return true }
        return false
    }

    private var finishDialogTitle: String {
        let unanswered = viewModel.questions.count - viewModel.answeredCount
        return unanswered > 0 ? "\(unanswered) soru boş kalacak" : "Sınavı bitirmek istiyor musun?"
    }

    private var finishDialogMessage: String {
        let unanswered = viewModel.questions.count - viewModel.answeredCount
        if unanswered > 0 {
            return "Boş bıraktığın sorular yanlış sayılmaz ama Hata Havuzu'na girip tekrar karşına çıkar."
        }
        return "Tüm soruları cevapladın. Sonucu görmek için bitirebilirsin."
    }

    // MARK: - Sınav gövdesi

    @ViewBuilder
    private func examBody(question: Question) -> some View {
        VStack(spacing: 0) {
            progressBar

            ScrollView {
                VStack(alignment: .leading, spacing: HMGSTheme.Layout.sectionSpacing) {
                    if viewModel.startedWithFewerThanRequested {
                        infoBanner(
                            "Bu seçimde \(viewModel.availableQuestionCount) soru vardı, sınav bu kadar soruyla başladı."
                        )
                    }

                    questionCard(question)
                    optionList(question)
                    reportRow(question)
                }
                .padding()
                // Alt aksiyon çubuğunun altında kalan içerik olmasın.
                .padding(.bottom, 8)
                // Soru değişince listeyi en üste al — kullanıcı yeni sorunun
                // ortasında başlamasın.
                .id(question.id)
            }
            .scrollDismissesKeyboard(.immediately)

            navigationBar(question: question)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(HMGSTheme.Colors.tertiaryBackground)
                Rectangle()
                    .fill(HMGSTheme.Colors.accent)
                    .frame(width: geo.size.width * viewModel.progressRatio)
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)   // aynı bilgi sağ üstteki "3/20" etiketinde var
    }

    private func questionCard(_ question: Question) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: question.subject.journeyIcon)
                    .font(.caption)
                Text(question.subject.displayName)
                    .font(.caption.weight(.semibold))
                if !question.topicTag.isEmpty {
                    Text("· \(question.topicTag)")
                        .font(.caption)
                        .foregroundStyle(HMGSTheme.Colors.tertiaryLabel)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(HMGSTheme.Colors.secondaryLabel)

            Text(question.prompt)
                .hmgsQuestionTextStyle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .hmgsCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(question.subject.displayName). Soru: \(question.prompt)")
    }

    private func optionList(_ question: Question) -> some View {
        VStack(spacing: HMGSTheme.Layout.optionSpacing) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, text in
                OptionRow(
                    letter: Question.optionLetter(index),
                    text: text,
                    isSelected: viewModel.answers[question.id] == index
                ) {
                    if viewModel.answers[question.id] == index {
                        viewModel.clearSelection()
                    } else {
                        viewModel.select(optionIndex: index)
                    }
                    Haptics.selection()
                }
            }
        }
    }

    private func reportRow(_ question: Question) -> some View {
        HStack {
            Spacer()
            if let url = FeedbackComposer.reportQuestionURL(question: question) {
                Link(destination: url) {
                    Label("Bu soruda hata var", systemImage: "flag")
                        .font(.caption)
                        .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                        .hmgsTapTarget()
                }
                .accessibilityHint("Bu soruyla ilgili hata bildirmek için e-posta taslağı açar.")
            }
        }
    }

    private func infoBanner(_ text: String) -> some View {
        Label(text, systemImage: "info.circle")
            .font(HMGSTheme.Typography.caption)
            .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                HMGSTheme.Colors.tertiaryBackground,
                in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.controlCornerRadius, style: .continuous)
            )
    }

    /// Alt aksiyon çubuğu: ana eylem başparmak bölgesinde, ekranın altında.
    /// "Önceki Soru" bilinçli olarak sönük — asıl eylem ileri gitmek.
    @ViewBuilder
    private func navigationBar(question: Question) -> some View {
        let hasAnswer = viewModel.answers[question.id] != nil
        let isLast = viewModel.isLastQuestion

        HStack(spacing: 12) {
            Button {
                viewModel.goPrevious()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                    .hmgsTapTarget()
            }
            .disabled(viewModel.currentIndex == 0)
            .opacity(viewModel.currentIndex == 0 ? 0.3 : 1)
            .accessibilityLabel("Önceki soru")

            Button {
                if isLast {
                    showFinishConfirm = true
                } else {
                    viewModel.goNext()
                }
            } label: {
                Text(isLast ? "Sınavı Bitir" : (hasAnswer ? "Sonraki Soru" : "Boş Bırak ve Geç"))
            }
            .buttonStyle(HMGSPrimaryButtonStyle(
                tint: hasAnswer || isLast ? HMGSTheme.Colors.accent : HMGSTheme.Colors.secondaryLabel
            ))
            .accessibilityHint(hasAnswer ? "" : "Bu soruyu cevaplamadan geçersen boş sayılır.")
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(.bar)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isExamRunning {
            ToolbarItem(placement: .topBarLeading) {
                Button("Bitir") { showFinishConfirm = true }
                    .foregroundStyle(HMGSTheme.Colors.destructive)
                    .accessibilityLabel("Sınavı bitir")
            }
            ToolbarItem(placement: .principal) {
                if let timer = viewModel.timer {
                    TimerLabel(timer: timer)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showQuestionGrid = true
                } label: {
                    Text("\(viewModel.currentIndex + 1)/\(viewModel.questions.count)")
                        .font(HMGSTheme.Typography.lawReference)
                        .foregroundStyle(HMGSTheme.Colors.accent)
                }
                .accessibilityLabel("Soru \(viewModel.currentIndex + 1) / \(viewModel.questions.count). Soru listesini aç.")
            }
        }
    }
}

/// Saat ayrı bir görünüm: her saniye sadece burası yeniden çiziliyor, tüm sınav
/// ekranı değil.
private struct TimerLabel: View {
    @ObservedObject var timer: TimerEngine

    var body: some View {
        Text(timer.formatted)
            .font(.headline.monospacedDigit())
            .foregroundStyle(isRunningLow ? HMGSTheme.Colors.destructive : HMGSTheme.Colors.label)
            .accessibilityLabel(timer.accessibilityText)
    }

    /// Son 60 saniyede saat kırmızıya döner. Renk TEK BAŞINA bilgi taşımıyor —
    /// VoiceOver zaten kalan süreyi okuyor.
    private var isRunningLow: Bool {
        timer.displaySeconds > 0 && timer.displaySeconds <= 60
    }
}

/// "12/40" etiketine dokununca açılan soru ızgarası — uzun bir denemede
/// "boş bıraktığım 7. soruya döneyim" ihtiyacı gerçek ve sık.
private struct QuestionGridSheet: View {
    @ObservedObject var viewModel: ActiveExamViewModel
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 52), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(viewModel.questions.enumerated()), id: \.element.id) { index, question in
                        let isAnswered = viewModel.answers[question.id] != nil
                        let isCurrent = index == viewModel.currentIndex
                        Button {
                            viewModel.jump(to: index)
                            dismiss()
                        } label: {
                            Text("\(index + 1)")
                                .font(.subheadline.weight(.semibold).monospacedDigit())
                                .foregroundStyle(isAnswered ? HMGSTheme.Colors.onAccent : HMGSTheme.Colors.label)
                                .frame(width: 52, height: 44)
                                .background(
                                    isAnswered ? HMGSTheme.Colors.accent : HMGSTheme.Colors.cardBackground,
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(isCurrent ? HMGSTheme.Colors.warning : .clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Soru \(index + 1), \(isAnswered ? "cevaplandı" : "boş")")
                    }
                }
                .padding()
            }
            .navigationTitle("Sorular")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text("\(viewModel.answeredCount) cevaplandı · \(viewModel.questions.count - viewModel.answeredCount) boş")
                    .font(.footnote)
                    .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                    .padding()
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct OptionRow: View {
    let letter: String
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? HMGSTheme.Colors.accent : HMGSTheme.Colors.tertiaryBackground)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(HMGSTheme.Colors.onAccent)
                    } else {
                        Text(letter)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                    }
                }
                .frame(width: 30, height: 30)

                Text(text)
                    .font(HMGSTheme.Typography.optionText)
                    .foregroundStyle(HMGSTheme.Colors.label)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: HMGSTheme.Layout.minimumTapTarget, alignment: .leading)
            .background(
                isSelected ? HMGSTheme.Colors.accent.opacity(0.12) : HMGSTheme.Colors.cardBackground,
                in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.controlCornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HMGSTheme.Layout.controlCornerRadius, style: .continuous)
                    .stroke(isSelected ? HMGSTheme.Colors.accent : .clear, lineWidth: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: HMGSTheme.Layout.controlCornerRadius))
        }
        .buttonStyle(.plain)
        // Seçili olduğu bilgisi renkle değil, VoiceOver'ın kendi "seçili" durumuyla
        // da veriliyor — renk tek başına bilgi taşımıyor.
        .accessibilityLabel("\(letter) şıkkı: \(text)")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityHint(isSelected ? "Seçimi kaldırmak için tekrar dokun." : "")
    }
}
