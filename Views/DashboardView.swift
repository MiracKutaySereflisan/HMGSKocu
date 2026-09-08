import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject private var store: AppDataStore
    /// Tek bir sınav başlatma kanalı — hem yeni deneme hem "kaldığın yerden devam"
    /// aynı hedefi kullanıyor (bkz. `ExamLaunch`).
    @State private var launch: ExamLaunch?
    @State private var showGoalPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HMGSTheme.Layout.sectionSpacing) {
                greeting
                if let exam = viewModel.resumableExam {
                    resumeCard(exam)
                }
                todayCard
                quickActions
                recentSessionsSection
            }
            .padding()
        }
        .hmgsAmbientBackground()
        .navigationTitle("Ana Sayfa")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .examDestination($launch)
        .confirmationDialog("Günlük hedefin", isPresented: $showGoalPicker, titleVisibility: .visible) {
            ForEach(DailyGoal.options, id: \.self) { goal in
                Button("\(goal) soru") { viewModel.setDailyGoal(goal) }
            }
            Button("Vazgeç", role: .cancel) {}
        }
    }

    // MARK: - Selamlama

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(timeOfDayGreeting), \(store.displayName)")
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                if viewModel.streak > 0 {
                    Label("\(viewModel.streak) gün üst üste", systemImage: "flame.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(HMGSTheme.Colors.warning)
                } else {
                    Text("Bugün nereden devam edelim?")
                        .font(.subheadline)
                        .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timeOfDayGreeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 0..<6: return "İyi çalışmalar"
        case 6..<12: return "Günaydın"
        case 12..<18: return "İyi günler"
        default: return "İyi akşamlar"
        }
    }

    // MARK: - Yarım kalan sınav

    private func resumeCard(_ exam: InProgressExam) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "pause.circle.fill")
                    .font(.title2)
                    .foregroundStyle(HMGSTheme.Colors.warning)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Yarım kalan sınavın var")
                        .font(.subheadline.weight(.semibold))
                    Text("\(exam.scope.label) · \(exam.answeredCount)/\(exam.questionIDs.count) cevaplandı")
                        .font(.caption)
                        .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button {
                    launch = ExamLaunch(
                        configuration: viewModel.resumeConfiguration(for: exam),
                        resuming: exam
                    )
                } label: {
                    Text("Devam Et")
                }
                .buttonStyle(HMGSPrimaryButtonStyle())

                Button(role: .destructive) {
                    Task { await viewModel.discardResumableExam() }
                } label: {
                    Text("Sil")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HMGSTheme.Colors.destructive)
                        .frame(minWidth: 64, minHeight: HMGSTheme.Layout.minimumTapTarget)
                }
                .buttonStyle(.plain)
            }
        }
        .hmgsCard()
    }

    // MARK: - Bugün

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Bugünkü Hedefin")
                    .font(.headline)
                Spacer()
                Button {
                    showGoalPicker = true
                } label: {
                    Label("\(viewModel.dailyGoal) soru", systemImage: "slider.horizontal.3")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HMGSTheme.Colors.accent)
                }
                .accessibilityLabel("Günlük hedefi değiştir. Şu an \(viewModel.dailyGoal) soru.")
            }

            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(HMGSTheme.Colors.tertiaryBackground, lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: viewModel.goalRatio)
                        .stroke(
                            LinearGradient(
                                colors: [HMGSTheme.Colors.accent, HMGSTheme.Colors.accent.opacity(0.6)],
                                startPoint: .topTrailing, endPoint: .bottomLeading
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(viewModel.todaySolvedCount)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Text("/ \(viewModel.dailyGoal)")
                            .font(.caption2)
                            .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                    }
                    .padding(12)
                }
                .frame(width: 92, height: 92)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Bugün \(viewModel.todaySolvedCount) soru çözüldü, hedef \(viewModel.dailyGoal).")

                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.todaySolvedCount == 0 {
                        Text("Bugün henüz soru çözmedin.")
                            .font(.subheadline)
                            .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Label("Doğru oranı: \(Format.percent(viewModel.todayCorrectRate))", systemImage: "target")
                            .font(.subheadline)
                            .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                    }
                    if viewModel.mistakePoolCount > 0 {
                        Label("Havuzda \(viewModel.mistakePoolCount) soru bekliyor", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(HMGSTheme.Colors.warning)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .hmgsCard()
    }

    // MARK: - Hızlı başlat

    private var quickActions: some View {
        VStack(spacing: 12) {
            Button {
                launch = ExamLaunch(
                    configuration: ExamConfiguration(scope: .fullHMGS, questionCount: 20, timeMode: .hmgsStandard)
                )
            } label: {
                Label("20 Soruluk Hızlı Deneme", systemImage: "play.fill")
            }
            .buttonStyle(HMGSPrimaryButtonStyle())
            .accessibilityHint("Tüm HMGS müfredatından, gerçek ders dağılımıyla 20 soruluk süreli deneme başlatır.")

            Button {
                launch = ExamLaunch(
                    configuration: ExamConfiguration(
                        scope: .fullHMGS,
                        questionCount: ScoringEngine.hmgsFullQuestionCount,
                        timeMode: .hmgsStandard
                    )
                )
            } label: {
                Label("Tam Deneme (120 soru · 155 dk)", systemImage: "flag.checkered")
            }
            .buttonStyle(HMGSSecondaryButtonStyle())
        }
    }

    // MARK: - Son denemeler

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Son Denemelerim").font(.headline)
                Spacer()
                if !viewModel.allSessions.isEmpty {
                    NavigationLink("Hepsini Gör") {
                        AllSessionsView(sessions: viewModel.allSessions)
                    }
                    .font(.subheadline)
                }
            }

            if viewModel.isLoading && viewModel.recentSessions.isEmpty {
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, 24)
            } else if viewModel.recentSessions.isEmpty {
                ContentUnavailableView {
                    Label("Henüz bir deneme yok", systemImage: "flag.checkered")
                } description: {
                    Text("İlk denemeni çözünce sonuçların burada birikmeye başlar.")
                }
                .padding(.top, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.recentSessions) { session in
                            RecentSessionCard(session: session)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

private struct RecentSessionCard: View {
    let session: ExamSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: session.scope.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HMGSTheme.Colors.accent)
                Text(session.scope.label)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Text("\(session.correctCount) / \(session.totalCount) doğru")
                .font(.caption.weight(.medium))
            Text(Format.sessionDate.string(from: session.startedAt))
                .font(.caption2)
                .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
        }
        .frame(width: 170, height: 118, alignment: .leading)
        .hmgsCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.scope.label): \(session.totalCount) soruda \(session.correctCount) doğru")
    }
}

private struct AllSessionsView: View {
    let sessions: [ExamSession]

    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView("Kayıtlı deneme yok", systemImage: "tray")
            } else {
                List(sessions) { session in
                    VStack(alignment: .leading, spacing: 6) {
                        Label(session.scope.label, systemImage: session.scope.icon)
                            .font(.headline)
                        Text("\(session.correctCount)/\(session.totalCount) doğru · Puan \(Int(session.scoreOutOf100.rounded())) · \(Format.duration(session.elapsedSeconds))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(Format.sessionDate.string(from: session.startedAt))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .navigationTitle("Tüm Denemeler")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { DashboardView() }
        .environmentObject(AppDataStore.shared)
}
