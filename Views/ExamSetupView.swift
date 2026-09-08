// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import SwiftUI

struct ExamSetupView: View {
    @StateObject private var viewModel = ExamSetupViewModel()
    @State private var launch: ExamLaunch?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HMGSTheme.Layout.sectionSpacing) {
                scopeSection
                questionCountSection
                timeSection
                startButton
                contentNote
            }
            .padding()
        }
        .hmgsAmbientBackground()
        .navigationTitle("Sınav Ayarları")
        .examDestination($launch)
        .task { viewModel.refreshAvailableCount() }
    }

    // MARK: - Kapsam

    private var scopeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HMGSSectionLabel("Sınav Kapsamı")

            VStack(spacing: 10) {
                ForEach(ExamSetupViewModel.ScopeKind.allCases) { kind in
                    scopeCard(kind)
                }
            }

            if viewModel.scopeKind == .bySubject {
                NavigationLink {
                    SubjectMultiPicker(viewModel: viewModel)
                } label: {
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(HMGSTheme.Colors.accent)
                        Text("Dersler")
                            .foregroundStyle(HMGSTheme.Colors.label)
                        Spacer()
                        Text(subjectSummary)
                            .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                            .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(HMGSTheme.Colors.tertiaryLabel)
                    }
                    .frame(minHeight: HMGSTheme.Layout.minimumTapTarget)
                    .hmgsCard()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func scopeCard(_ kind: ExamSetupViewModel.ScopeKind) -> some View {
        let isSelected = viewModel.scopeKind == kind
        return Button {
            viewModel.scopeKind = kind
        } label: {
            HStack(spacing: 12) {
                Image(systemName: kind.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? HMGSTheme.Colors.onAccent : HMGSTheme.Colors.accent)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isSelected ? HMGSTheme.Colors.onAccent : HMGSTheme.Colors.label)
                    Text(kind.detail)
                        .font(.caption)
                        .foregroundStyle(isSelected ? HMGSTheme.Colors.onAccent.opacity(0.85) : HMGSTheme.Colors.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(HMGSTheme.Colors.onAccent)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: HMGSTheme.Layout.minimumTapTarget, alignment: .leading)
            .background(
                isSelected ? AnyShapeStyle(HMGSTheme.Colors.accent) : AnyShapeStyle(HMGSTheme.Colors.cardBackground),
                in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.cardCornerRadius, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }

    private var subjectSummary: String {
        let selected = viewModel.selectedSubjectsOrdered
        if selected.isEmpty { return "Seç" }
        if selected.count == 1, let only = selected.first { return only.displayName }
        return "\(selected.count) ders"
    }

    // MARK: - Soru sayısı

    private var questionCountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HMGSSectionLabel("Soru Sayısı")

            VStack(spacing: 12) {
                HStack {
                    stepperButton(systemImage: "minus", label: "Azalt") { viewModel.decreaseCount() }
                        .disabled(viewModel.questionCount <= viewModel.questionCountRange.lowerBound)
                    Spacer()
                    VStack(spacing: 0) {
                        Text("\(viewModel.questionCount)")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .monospacedDigit()
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        Text("soru")
                            .font(.caption)
                            .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(viewModel.questionCount) soru")
                    Spacer()
                    stepperButton(systemImage: "plus", label: "Artır") { viewModel.increaseCount() }
                        .disabled(viewModel.questionCount >= viewModel.questionCountRange.upperBound)
                }

                if let poolText = viewModel.poolSizeText {
                    Label(poolText, systemImage: viewModel.poolWarningIsActive ? "exclamationmark.circle" : "info.circle")
                        .font(.caption)
                        .foregroundStyle(viewModel.poolWarningIsActive ? HMGSTheme.Colors.warning : HMGSTheme.Colors.secondaryLabel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .hmgsCard()
        }
    }

    private func stepperButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(HMGSTheme.Colors.onAccent)
                .frame(width: HMGSTheme.Layout.minimumTapTarget, height: HMGSTheme.Layout.minimumTapTarget)
                .background(HMGSTheme.Colors.accent, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Süre

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HMGSSectionLabel("Süre")

            Toggle(isOn: Binding(
                get: { viewModel.timeMode == .hmgsStandard },
                set: { viewModel.timeMode = $0 ? .hmgsStandard : .untimed }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HMGS Süre Temposu")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HMGSTheme.Colors.label)
                    Text(viewModel.timeLimitPreviewText)
                        .font(.caption)
                        .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(HMGSTheme.Colors.accent)
            .frame(minHeight: HMGSTheme.Layout.minimumTapTarget)
            .hmgsCard()
        }
    }

    // MARK: - Başlat

    private var startButton: some View {
        Button {
            launch = ExamLaunch(configuration: viewModel.makeConfiguration())
        } label: {
            Label("Sınavı Başlat", systemImage: "flag.checkered")
        }
        .buttonStyle(HMGSPrimaryButtonStyle())
        .disabled(!viewModel.canStart)
    }

    private var contentNote: some View {
        Text(ContentPolicy.shortNotice)
            .font(.caption2)
            .foregroundStyle(HMGSTheme.Colors.tertiaryLabel)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)
    }
}

private struct SubjectMultiPicker: View {
    @ObservedObject var viewModel: ExamSetupViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                HStack {
                    Button("Tümünü Seç") { viewModel.selectAllSubjects() }
                    Spacer()
                    Button("Temizle") { viewModel.clearSubjects() }
                        .foregroundStyle(HMGSTheme.Colors.destructive)
                }
                .font(.subheadline.weight(.semibold))
                .padding(.bottom, 4)

                ForEach(LegalSubject.displayOrdered) { subject in
                    let isSelected = viewModel.selectedSubjects.contains(subject)
                    Button {
                        viewModel.toggle(subject)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: subject.journeyIcon)
                                .foregroundStyle(HMGSTheme.Colors.accent)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(subject.displayName)
                                    .foregroundStyle(HMGSTheme.Colors.label)
                                    .multilineTextAlignment(.leading)
                                if subject.isOfficialHMGSSubject {
                                    Text("Sınavda \(subject.officialWeight) soru")
                                        .font(.caption2)
                                        .foregroundStyle(HMGSTheme.Colors.tertiaryLabel)
                                } else {
                                    Text("Ek pratik dersi")
                                        .font(.caption2)
                                        .foregroundStyle(HMGSTheme.Colors.tertiaryLabel)
                                }
                            }
                            Spacer(minLength: 0)
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isSelected ? HMGSTheme.Colors.accent : HMGSTheme.Colors.tertiaryLabel)
                        }
                        .frame(minHeight: HMGSTheme.Layout.minimumTapTarget)
                        .hmgsCard()
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
                }
            }
            .padding()
        }
        .hmgsAmbientBackground()
        .navigationTitle("Dersler")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { ExamSetupView() }
}
