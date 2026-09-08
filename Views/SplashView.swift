import SwiftUI

/// Açılışta kısa süre görünen, logo + rastgele bir hukuk özdeyişi gösteren ekran.
///
/// Süre bilinçli olarak kısa (1,4 sn): açılış ekranı ilk kullanımda hoş, onuncu
/// kullanımda engeldir. Kullanıcı ekrana dokunarak da geçebiliyor.
struct SplashView: View {
    @State private var quote = LawQuote.random()
    @State private var isVisible = false
    @State private var didFinish = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var onFinished: () -> Void

    private var deepAccent: Color { Color(red: 12/255, green: 10/255, blue: 38/255) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [HMGSTheme.Colors.accent, deepAccent],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 26) {
                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
                    .accessibilityHidden(true)

                Text(AppInfo.displayName)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                VStack(spacing: 8) {
                    Text("“\(quote.text)”")
                        .font(.callout)
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("— \(quote.author)")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: 340)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.cardCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: HMGSTheme.Layout.cardCornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal, 32)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(quote.text) — \(quote.author)")
            }
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible || reduceMotion ? 1 : 0.97)
        }
        // Beklemek istemeyen kullanıcı dokunup geçebilsin.
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear {
            if reduceMotion {
                isVisible = true
            } else {
                withAnimation(.easeOut(duration: 0.5)) { isVisible = true }
            }
        }
        // `DispatchQueue.main.asyncAfter` yerine `.task`: bu blok ana iş
        // parçacığında çalışıyor (SwiftUI garantisi) ve ekran kapanırsa iş de
        // iptal oluyor — açılış ekranı kapandıktan sonra tetiklenen öksüz bir
        // geri çağrı kalmıyor.
        .task {
            try? await Task.sleep(for: .seconds(1.4))
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    /// İki kez çağrılmaya karşı korumalı — kullanıcı dokunurken zamanlayıcı da
    /// dolarsa onboarding iki kez tetiklenmesin.
    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinished()
    }
}

#Preview {
    SplashView(onFinished: {})
}
