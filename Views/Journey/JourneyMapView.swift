import SwiftUI

/// Ders ders, aşama aşama ilerlenen yol haritası. "Sınav" sekmesindeki serbest
/// pratik akışına dokunmaz — aynı soru havuzunu ve aynı sınav motorunu farklı bir
/// giriş noktasından kullanır.
struct JourneyMapView: View {
    @StateObject private var viewModel = JourneyViewModel()
    @State private var selectedSubject: LegalSubject?
    @State private var launch: ExamLaunch?

    private var currentSubject: LegalSubject {
        selectedSubject ?? LegalSubject.displayOrdered.first ?? .medeniHukuk
    }

    var body: some View {
        ScrollView {
            VStack(spacing: HMGSTheme.Layout.sectionSpacing) {
                levelHeader
                subjectPicker
                if viewModel.isLoading && viewModel.allQuestions.isEmpty {
                    // Aşağı çekip yenilerken yolu boşaltıp ProgressView göstermiyoruz;
                    // sadece ilk yüklemede.
                    ProgressView().padding(.top, 60)
                } else if let message = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label("Yolculuk yüklenemedi", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Tekrar Dene") { Task { await viewModel.load() } }
                            .buttonStyle(HMGSSecondaryButtonStyle())
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 30)
                } else {
                    pathSection
                }
            }
            .padding(.vertical)
        }
        .hmgsAmbientBackground()
        .navigationTitle("Yolculuk")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .examDestination($launch, journeyViewModel: viewModel)
    }

    // MARK: - Seviye başlığı

    private var levelHeader: some View {
        let info = viewModel.levelInfo
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [HMGSTheme.Colors.accent, HMGSTheme.Colors.accent.opacity(0.7)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: 46, height: 46)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(HMGSTheme.Colors.onAccent)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Seviye \(info.level)").font(.headline)
                    Spacer()
                    Text("\(info.xpIntoLevel) / \(info.xpForLevel) XP")
                        .font(.caption.weight(.medium).monospacedDigit())
                        .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                }
                ProgressView(value: Double(info.xpIntoLevel), total: Double(max(1, info.xpForLevel)))
                    .tint(HMGSTheme.Colors.accent)
            }
        }
        .hmgsCard()
        .padding(.horizontal)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Seviye \(info.level). Sonraki seviyeye \(max(0, info.xpForLevel - info.xpIntoLevel)) XP kaldı.")
    }

    // MARK: - Ders seçici

    private var subjectPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LegalSubject.displayOrdered) { subject in
                        subjectChip(subject).id(subject)
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: currentSubject) { _, newValue in
                withAnimation(HMGSTheme.Motion.standard) { proxy.scrollTo(newValue, anchor: .center) }
            }
        }
    }

    private func subjectChip(_ subject: LegalSubject) -> some View {
        let isSelected = subject == currentSubject
        let stages = viewModel.stages(for: subject)
        let cleared = viewModel.clearedCount(for: subject)

        return Button {
            selectedSubject = subject
        } label: {
            HStack(spacing: 8) {
                Image(systemName: subject.journeyIcon)
                    .font(.caption.weight(.semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(subject.displayName)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    if !stages.isEmpty {
                        Text("\(cleared)/\(stages.count) aşama")
                            .font(.caption2)
                            .opacity(0.85)
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: HMGSTheme.Layout.minimumTapTarget)
            .foregroundStyle(isSelected ? HMGSTheme.Colors.onAccent : HMGSTheme.Colors.label)
            .background(
                isSelected ? AnyShapeStyle(HMGSTheme.Colors.accent) : AnyShapeStyle(HMGSTheme.Colors.cardBackground),
                in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.controlCornerRadius, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(subject.displayName), \(stages.count) aşamanın \(cleared) tanesi geçildi")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - Yol

    // Aşama düğümlerinin dikey aralığı ve yolun genliği — hem düğümler hem de
    // altlarındaki şerit AYNI formülden konum aldığı için asla birbirinden kayamaz.
    private let nodeRowHeight: CGFloat = 170
    private let nodeSize: CGFloat = 64
    private let pathTopInset: CGFloat = 110
    private let pathBottomInset: CGFloat = 60

    @ViewBuilder
    private var pathSection: some View {
        let stages = viewModel.stages(for: currentSubject)
        if stages.isEmpty {
            ContentUnavailableView {
                Label("Bu derste henüz aşama yok", systemImage: "map")
            } description: {
                Text("Bu ders için soru eklendiğinde yol otomatik olarak oluşur.")
            }
            .padding(.top, 40)
        } else {
            let currentIndex = stages.firstIndex { viewModel.isUnlocked($0) && !viewModel.isCompleted($0) }
            GeometryReader { geo in
                let points = stages.indices.map { nodeCenter(index: $0, width: geo.size.width) }
                ZStack(alignment: .topLeading) {
                    pathRibbon(points: points)
                    ForEach(Array(stages.enumerated()), id: \.element.id) { index, stage in
                        stageNode(stage, isCurrent: index == currentIndex)
                            .position(points[index])
                    }
                }
            }
            .frame(height: pathTopInset + CGFloat(stages.count) * nodeRowHeight + pathBottomInset)
            .padding(.top, 12)
        }
    }

    private func nodeCenter(index: Int, width: CGFloat) -> CGPoint {
        let amplitude = max(0, min(100, (width - 150) / 2))
        let x = index.isMultiple(of: 2) ? width / 2 - amplitude : width / 2 + amplitude
        let y = pathTopInset + nodeRowHeight * (CGFloat(index) + 0.5)
        return CGPoint(x: x, y: y)
    }

    private func pathRibbon(points: [CGPoint]) -> some View {
        let curve = Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            guard points.count > 1 else { return }
            for index in 1..<points.count {
                let previous = points[index - 1]
                let current = points[index]
                path.addQuadCurve(to: current, control: CGPoint(x: current.x, y: previous.y))
            }
        }
        return ZStack {
            curve.stroke(HMGSTheme.Colors.accent.opacity(0.16),
                         style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
            curve.stroke(HMGSTheme.Colors.accent.opacity(0.55),
                         style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [1, 12]))
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func stageNode(_ stage: Stage, isCurrent: Bool) -> some View {
        let completed = viewModel.isCompleted(stage)
        let unlocked = viewModel.isUnlocked(stage)

        Button {
            guard unlocked else { return }
            launch = ExamLaunch(
                configuration: viewModel.configuration(for: stage),
                explicitQuestionIDs: stage.questionIDs
            )
        } label: {
            ZStack {
                Circle()
                    .fill(nodeFill(completed: completed, unlocked: unlocked))
                    .frame(width: nodeSize, height: nodeSize)
                    .shadow(color: HMGSTheme.Colors.accent.opacity(unlocked ? 0.3 : 0), radius: 8, y: 4)
                if !unlocked {
                    Circle()
                        .strokeBorder(HMGSTheme.Colors.tertiaryLabel.opacity(0.4),
                                      style: StrokeStyle(lineWidth: 2, dash: [4, 5]))
                        .frame(width: nodeSize, height: nodeSize)
                }
                Image(systemName: completed ? "checkmark" : (unlocked ? "book.fill" : "lock.fill"))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(unlocked || completed ? HMGSTheme.Colors.onAccent : HMGSTheme.Colors.secondaryLabel)
            }
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
        .accessibilityLabel("\(stage.title), \(stage.dominantTopicTag)")
        .accessibilityValue(completed ? "Geçildi" : (unlocked ? "Açık, \(stage.questionIDs.count) soru" : "Kilitli"))
        .accessibilityHint(unlocked ? "Aşamayı başlatmak için dokun." : "Önceki aşamayı geçince açılır.")
        .overlay(alignment: .top) {
            if isCurrent {
                VStack(spacing: 2) {
                    Text("Buradasın")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .foregroundStyle(HMGSTheme.Colors.onAccent)
                        .background(HMGSTheme.Colors.accent, in: Capsule())
                    MascotView(mood: .idle, size: 52)
                }
                .fixedSize()
                .offset(y: -96)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 2) {
                Text(stage.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                Text(stage.dominantTopicTag)
                    .font(.caption2)
                    .foregroundStyle(HMGSTheme.Colors.tertiaryLabel)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 132)
            .fixedSize(horizontal: false, vertical: true)
            .offset(y: 42)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func nodeFill(completed: Bool, unlocked: Bool) -> AnyShapeStyle {
        if completed {
            return AnyShapeStyle(LinearGradient(
                colors: [HMGSTheme.Colors.success, HMGSTheme.Colors.success.opacity(0.75)],
                startPoint: .top, endPoint: .bottom
            ))
        }
        if unlocked {
            return AnyShapeStyle(LinearGradient(
                colors: [HMGSTheme.Colors.accent, HMGSTheme.Colors.accent.opacity(0.75)],
                startPoint: .top, endPoint: .bottom
            ))
        }
        return AnyShapeStyle(HMGSTheme.Colors.tertiaryBackground)
    }
}

#Preview {
    NavigationStack { JourneyMapView() }
}
