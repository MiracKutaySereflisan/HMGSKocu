// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import SwiftUI

struct MistakePoolView: View {
    @StateObject private var viewModel = MistakePoolViewModel()
    @State private var launch: ExamLaunch?

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HMGSTheme.Layout.sectionSpacing) {
                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 60)
                } else if viewModel.isEmpty && viewModel.totalReclaimed == 0 {
                    emptyState
                } else {
                    summaryHeader
                    if !viewModel.subjectCounts.isEmpty { wrongSection }
                    if !viewModel.blankSubjectCounts.isEmpty { blankSection }
                    if viewModel.totalReclaimed > 0 { reclaimedSection }
                }
            }
            .padding()
        }
        .hmgsAmbientBackground()
        .navigationTitle("Hata Havuzu")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .examDestination($launch)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Hata havuzun boş", systemImage: "checkmark.circle")
        } description: {
            Text("Yanlış yaptığın ve boş bıraktığın sorular otomatik olarak burada birikir — doğru yapana kadar tekrar tekrar karşına çıkarlar.")
        }
        .padding(.top, 50)
    }

    private var summaryHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [HMGSTheme.Colors.destructive, HMGSTheme.Colors.destructive.opacity(0.7)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: 46, height: 46)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.totalMistakes) yanlış · \(viewModel.totalBlanks) boş")
                    .font(.headline)
                Text("Tek tek eritebilirsin — doğru yaptığın soru havuzdan çıkar.")
                    .font(.caption)
                    .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .hmgsCard()
        .accessibilityElement(children: .combine)
    }

    private var wrongSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HMGSSectionLabel("Yanlış Yaptıkların")

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.subjectCounts) { progress in
                    SubjectMistakeCard(progress: progress, label: "yanlış", accent: HMGSTheme.Colors.destructive) {
                        start(subject: progress.subject, kind: .wrong)
                    }
                }
            }

            Button {
                start(subject: nil, kind: .wrong)
            } label: {
                Label("Tüm Yanlışları Tekrar Çöz", systemImage: "flame.fill")
            }
            .buttonStyle(HMGSPrimaryButtonStyle(tint: HMGSTheme.Colors.destructive))
        }
    }

    private var blankSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HMGSSectionLabel("Boş Bıraktıkların")
            Text("Sınavı erken bitirdiğin için cevapsız kalan sorular — yanlış sayılmazlar, doğruluk oranını düşürmezler ama tekrar karşına çıkarlar.")
                .font(.caption)
                .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.blankSubjectCounts) { progress in
                    SubjectMistakeCard(progress: progress, label: "boş", accent: HMGSTheme.Colors.warning) {
                        start(subject: progress.subject, kind: .blank)
                    }
                }
            }

            Button {
                start(subject: nil, kind: .blank)
            } label: {
                Label("Tüm Boşları Tekrar Çöz", systemImage: "questionmark.circle.fill")
            }
            .buttonStyle(HMGSSecondaryButtonStyle(tint: HMGSTheme.Colors.warning))
        }
    }

    private var reclaimedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HMGSSectionLabel("Kazanılan Sorular")
            Text("Daha önce yanlış yapıp sonradan doğruya çevirdiğin sorular — \(viewModel.totalReclaimed) tane.")
                .font(.caption)
                .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.reclaimedSubjectCounts) { progress in
                    WonSubjectCard(progress: progress)
                }
            }
        }
    }

    /// Boş bir listeyle sınav başlatmayı engelleyen tek giriş noktası.
    private func start(subject: LegalSubject?, kind: MistakePoolViewModel.RetakeKind) {
        guard let plan = viewModel.retakePlan(subject: subject, kind: kind) else { return }
        launch = ExamLaunch(configuration: plan.configuration, explicitQuestionIDs: plan.ids)
    }
}

private struct SubjectMistakeCard: View {
    let progress: SubjectProgress
    var label: String
    var accent: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: progress.subject.journeyIcon)
                        .font(.caption)
                        .foregroundStyle(accent)
                    Text(progress.subject.displayName)
                        .font(.subheadline.bold())
                        .foregroundStyle(HMGSTheme.Colors.label)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Text("\(progress.wrong) \(label)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accent)
            }
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
            .hmgsCard()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(progress.subject.displayName): \(progress.wrong) \(label). Tekrar çözmek için dokun.")
    }
}

private struct WonSubjectCard: View {
    let progress: SubjectProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: progress.subject.journeyIcon)
                    .font(.caption)
                    .foregroundStyle(HMGSTheme.Colors.success)
                Text(progress.subject.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(HMGSTheme.Colors.label)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Label("\(progress.correct) kazanıldı", systemImage: "arrow.uturn.up")
                .font(.caption.weight(.semibold))
                .foregroundStyle(HMGSTheme.Colors.success)
        }
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .hmgsCard()
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack { MistakePoolView() }
}
