import SwiftUI

/// Kısa, kaydırmalı uygulama turu — ilk açılışta bir kez otomatik gösterilir,
/// istenirse Profil'den tekrar izlenebilir.
struct AppTourView: View {
    var onFinished: () -> Void

    @State private var currentPage = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Page: Identifiable {
        let id: Int
        let useMascot: Bool
        let mascotMood: MascotView.Mood
        let icon: String
        let title: String
        let description: String
    }

    private let pages: [Page] = [
        Page(id: 0, useMascot: true, mascotMood: .idle, icon: "",
             title: "HMGS Koçu'na hoş geldin",
             description: "Soru çöz, hatalarını takip et, aşama aşama ilerle. Kukuk yol boyunca yanında."),
        Page(id: 1, useMascot: false, mascotMood: .idle, icon: "map.fill",
             title: "Yolculuk",
             description: "Her ders, aşama aşama ilerlenen bir yol. Bir aşamayı %70 doğruyla geçince bir sonraki açılır."),
        Page(id: 2, useMascot: false, mascotMood: .idle, icon: "doc.text.fill",
             title: "Sınav",
             description: "İstediğin dersten, istediğin sayıda soruyla çalış. Süreyi açarsan gerçek HMGS temposunda (120 soru / 155 dakika) çözersin."),
        Page(id: 3, useMascot: false, mascotMood: .idle, icon: "exclamationmark.triangle.fill",
             title: "Hata Havuzu",
             description: "Yanlış yaptığın ve boş bıraktığın sorular otomatik burada birikir; doğru yapana kadar tekrar karşına çıkar."),
        Page(id: 4, useMascot: true, mascotMood: .celebrating, icon: "",
             title: "Her şey cihazında",
             description: "Hesap açman gerekmiyor, hiçbir verin sunucuya gitmiyor. İnternet olmadan da tam çalışır.")
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [HMGSTheme.Colors.accent.opacity(0.18), HMGSTheme.Colors.background],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Atla") { onFinished() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                        .padding()
                        .hmgsTapTarget()
                }

                TabView(selection: $currentPage) {
                    ForEach(pages) { page in
                        pageView(page).tag(page.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(HMGSTheme.Motion.respectingReduceMotion(reduceMotion, HMGSTheme.Motion.standard)) {
                            currentPage += 1
                        }
                    } else {
                        onFinished()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "İleri" : "Hadi Başlayalım")
                }
                .buttonStyle(HMGSPrimaryButtonStyle())
                .padding()
            }
        }
    }

    @ViewBuilder
    private func pageView(_ page: Page) -> some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 24)

                if page.useMascot {
                    MascotView(mood: page.mascotMood, size: 110)
                } else {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [HMGSTheme.Colors.accent, HMGSTheme.Colors.accent.opacity(0.7)],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .frame(width: 96, height: 96)
                            .shadow(color: HMGSTheme.Colors.accent.opacity(0.3), radius: 14, y: 8)
                        Image(systemName: page.icon)
                            .font(.system(size: 38, weight: .bold))
                            .foregroundStyle(HMGSTheme.Colors.onAccent)
                    }
                    .accessibilityHidden(true)
                }

                Text(page.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 28)

                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    AppTourView(onFinished: {})
}
