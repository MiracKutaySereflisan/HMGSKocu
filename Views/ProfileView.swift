// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import SwiftUI

struct ProfileView: View {
    @StateObject private var dashboard = DashboardViewModel()
    @StateObject private var journey = JourneyViewModel()
    @EnvironmentObject private var store: AppDataStore

    @AppStorage(DefaultsKey.appearance) private var appearanceRaw = AppAppearance.system.rawValue
    @State private var unlockedAchievements: [Achievement] = []
    @State private var editingName = false
    @State private var nameDraft = ""
    @State private var showAppTour = false
    @State private var showDeleteConfirm = false
    @State private var showDeleteDoubleConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HMGSTheme.Layout.sectionSpacing) {
                profileHeader
                levelCard
                appearanceSection
                subjectAccuracySection
                achievementsSection
                aboutSection
                dangerZone
                versionFooter
            }
            .padding()
        }
        .hmgsAmbientBackground()
        .navigationTitle("Profil")
        .task { await reload() }
        .refreshable { await reload() }
        .alert("İsmini Güncelle", isPresented: $editingName) {
            TextField("İsim", text: $nameDraft)
                .textInputAutocapitalization(.words)
            Button("Kaydet") { store.setDisplayName(nameDraft) }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Bu isim yalnızca senin cihazında saklanır, hiçbir yere gönderilmez.")
        }
        .fullScreenCover(isPresented: $showAppTour) {
            AppTourView { showAppTour = false }
        }
        .confirmationDialog(
            "Tüm verilerin silinsin mi?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Devam Et", role: .destructive) { showDeleteDoubleConfirm = true }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Çözdüğün sorular, hata havuzun, Yolculuk ilerlemen ve başarımların silinir. Bu işlem geri alınamaz.")
        }
        .alert("Emin misin?", isPresented: $showDeleteDoubleConfirm) {
            Button("Evet, Hepsini Sil", role: .destructive) {
                Task {
                    await store.deleteAllData()
                    await reload()
                    Haptics.warning()
                }
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Bu son adım. Silinen ilerleme geri getirilemez.")
        }
    }

    private func reload() async {
        await dashboard.load()
        await journey.load()
        unlockedAchievements = (try? await store.fetchUnlockedAchievements()) ?? []
    }

    // MARK: - Başlık

    private var profileHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [HMGSTheme.Colors.accent, HMGSTheme.Colors.accent.opacity(0.7)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: 56, height: 56)
                Text(initials)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(HMGSTheme.Colors.onAccent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(store.displayName)
                    .font(.headline)
                    .lineLimit(1)
                if dashboard.streak > 0 {
                    Label("\(dashboard.streak) gün üst üste", systemImage: "flame.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(HMGSTheme.Colors.warning)
                }
            }
            Spacer(minLength: 0)
            Button {
                nameDraft = store.displayName
                editingName = true
            } label: {
                Text("Düzenle")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 14)
                    .frame(minHeight: HMGSTheme.Layout.minimumTapTarget)
                    .foregroundStyle(HMGSTheme.Colors.accent)
                    .background(HMGSTheme.Colors.accent.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("İsmini düzenle")
        }
        .hmgsCard()
    }

    private var initials: String {
        let name = store.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = name.first else { return "H" }
        return String(first).uppercased(with: Locale.turkish)
    }

    private var levelCard: some View {
        let info = journey.levelInfo
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [HMGSTheme.Colors.warning, HMGSTheme.Colors.warning.opacity(0.7)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(width: 46, height: 46)
                    Image(systemName: "star.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Seviye \(info.level)").font(.headline)
                    Text("Toplam \(journey.progress.totalXP) XP · \(journey.totalCompletedStages) aşama")
                        .font(.caption)
                        .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                }
                Spacer(minLength: 0)
            }
            ProgressView(value: Double(info.xpIntoLevel), total: Double(max(1, info.xpForLevel)))
                .tint(HMGSTheme.Colors.accent)
                .accessibilityLabel("Sonraki seviyeye \(max(0, info.xpForLevel - info.xpIntoLevel)) XP kaldı")
        }
        .hmgsCard()
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HMGSSectionLabel("Görünüm")
            Picker("Görünüm", selection: $appearanceRaw) {
                ForEach(AppAppearance.allCases) { option in
                    Text(option.label).tag(option.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .hmgsCard()
        }
    }

    // MARK: - Ders bazlı doğruluk

    private var subjectAccuracySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HMGSSectionLabel("Ders Bazlı Doğruluk")

            let solved = dashboard.subjectProgress.filter { $0.solved > 0 }
            if solved.isEmpty {
                Text("Soru çözmeye başlayınca hangi derste ne durumda olduğun burada görünecek.")
                    .font(.subheadline)
                    .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .hmgsCard()
            } else {
                VStack(spacing: 8) {
                    ForEach(solved) { progress in
                        SubjectAccuracyRow(progress: progress)
                    }
                }
            }
        }
    }

    // MARK: - Başarımlar

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HMGSSectionLabel("Başarımlar")
                Spacer()
                Text("\(unlockedAchievements.count)/\(AchievementCatalogue.all.count)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
            }

            VStack(spacing: 8) {
                ForEach(AchievementCatalogue.all) { achievement in
                    let unlocked = unlockedAchievements.contains { $0.id == achievement.id }
                    HStack(spacing: 10) {
                        Image(systemName: unlocked ? "rosette" : "lock.fill")
                            .foregroundStyle(unlocked ? HMGSTheme.Colors.warning : HMGSTheme.Colors.tertiaryLabel)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(achievement.title).font(.subheadline.weight(.semibold))
                            Text(achievement.detail)
                                .font(.caption)
                                .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(HMGSTheme.Colors.cardBackground, in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.controlCornerRadius, style: .continuous))
                    .opacity(unlocked ? 1 : 0.55)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(achievement.title), \(unlocked ? "açıldı" : "kilitli"). \(achievement.detail)")
                }
            }
        }
    }

    // MARK: - Hakkında

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HMGSSectionLabel("Hakkında")

            VStack(spacing: 0) {
                NavigationLink {
                    ContentNoticeView()
                } label: {
                    row(icon: "info.circle", title: "Sorular Hakkında")
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 48)

                Button {
                    showAppTour = true
                } label: {
                    row(icon: "play.rectangle", title: "Uygulama Turu")
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 48)

                NavigationLink {
                    PrivacyView()
                } label: {
                    row(icon: "hand.raised", title: "Gizlilik")
                }
                .buttonStyle(.plain)

                if let url = FeedbackComposer.supportURL() {
                    Divider().padding(.leading, 48)
                    Link(destination: url) {
                        row(icon: "envelope", title: "Bize Yaz")
                    }
                }
            }
            .background(HMGSTheme.Colors.cardBackground, in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.cardCornerRadius, style: .continuous))
        }
    }

    private func row(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(HMGSTheme.Colors.accent)
                .frame(width: 24)
            Text(title)
                .foregroundStyle(HMGSTheme.Colors.label)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(HMGSTheme.Colors.tertiaryLabel)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: HMGSTheme.Layout.minimumTapTarget + 6)
        .contentShape(Rectangle())
    }

    // MARK: - Tehlikeli bölge

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 10) {
            HMGSSectionLabel("Verilerim")
            Text("Tüm ilerlemen yalnızca bu cihazda. Dilediğin an tek dokunuşla silebilirsin.")
                .font(.caption)
                .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                .fixedSize(horizontal: false, vertical: true)

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Verilerimi Sil", systemImage: "trash")
            }
            .buttonStyle(HMGSSecondaryButtonStyle(tint: HMGSTheme.Colors.destructive))
        }
    }

    private var versionFooter: some View {
        Text("\(AppInfo.displayName) \(AppInfo.versionString)")
            .font(.caption2)
            .foregroundStyle(HMGSTheme.Colors.tertiaryLabel)
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
    }
}

private struct SubjectAccuracyRow: View {
    let progress: SubjectProgress

    private var accuracyColor: Color {
        switch progress.accuracy {
        case ..<0.5: return HMGSTheme.Colors.destructive
        case ..<0.7: return HMGSTheme.Colors.warning
        default: return HMGSTheme.Colors.success
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: progress.subject.journeyIcon)
                    .font(.caption)
                    .foregroundStyle(HMGSTheme.Colors.accent)
                    .frame(width: 20)
                Text(progress.subject.displayName)
                    .font(.subheadline)
                    .foregroundStyle(HMGSTheme.Colors.label)
                    .lineLimit(1)
                Spacer(minLength: 8)
                // Yüzde hem metin hem çubuk hem renkle veriliyor; renk tek başına
                // bilgi taşımıyor.
                Text("\(Format.percent(progress.accuracy)) · \(progress.solved) soru")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
            }
            ProgressView(value: progress.accuracy)
                .tint(accuracyColor)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(HMGSTheme.Colors.cardBackground, in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.controlCornerRadius, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(progress.subject.displayName): \(progress.solved) soruda \(Format.percent(progress.accuracy)) doğruluk")
    }
}

/// Sorunun kaynağı ve sınırları hakkında açık metin. App Store'a giden açıklamayla
/// ve gizlilik politikasıyla aynı cümleleri kullanıyor (tek kaynak: `ContentPolicy`).
struct ContentNoticeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Sorular Hakkında", systemImage: "info.circle.fill")
                    .font(.title3.bold())
                    .foregroundStyle(HMGSTheme.Colors.accent)

                Text(ContentPolicy.longNotice)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                if let url = FeedbackComposer.supportURL() {
                    Link(destination: url) {
                        Label("Hata bildir / bize yaz", systemImage: "envelope")
                    }
                    .buttonStyle(HMGSSecondaryButtonStyle())
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .background(HMGSTheme.Colors.background)
        .navigationTitle("Sorular Hakkında")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Gizlilik", systemImage: "hand.raised.fill")
                    .font(.title3.bold())
                    .foregroundStyle(HMGSTheme.Colors.accent)

                Text(ContentPolicy.privacyShort)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 12) {
                    privacyRow("Hesap yok", "Kayıt olman, e-posta ya da telefon vermen gerekmiyor.")
                    privacyRow("Sunucu yok", "Çözdüğün sorular, puanların ve ilerlemen cihazından çıkmıyor.")
                    privacyRow("İzleme yok", "Reklam kimliği okunmuyor, üçüncü taraf analiz aracı kullanılmıyor.")
                    privacyRow("Silme hakkı", "Profil > Verilerimi Sil ile her şeyi tek adımda silebilirsin.")
                    privacyRow("Yedek", "Cihazını iCloud'a yedekliyorsan ilerlemen o yedeğin içinde, senin hesabında kalır.")
                }

                if let url = AppInfo.privacyPolicyURL {
                    Link("Gizlilik politikasının tam metni", destination: url)
                        .font(.footnote)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .background(HMGSTheme.Colors.background)
        .navigationTitle("Gizlilik")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func privacyRow(_ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(HMGSTheme.Colors.success)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack { ProfileView() }
        .environmentObject(AppDataStore.shared)
}
