import SwiftUI

/// Yolculuk maskotu "Kukuk" (hukuk kelime oyunu). Kodla çizilmiş — illüstrasyon
/// ya da Lottie dosyası gerektirmiyor, dolayısıyla lisans sorunu da yok
/// (bkz. Docs/LICENSES.md). İleride gerçek bir illüstrasyonla değiştirmek için
/// yalnızca bu görünümün gövdesi değişir; çağıran yerler `mood` ve `size` verir.
struct MascotView: View {
    enum Mood: Equatable {
        case idle
        case celebrating
    }

    var mood: Mood = .idle
    var size: CGFloat = 96

    @State private var bounce = false
    @State private var sparkle = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if mood == .celebrating { sparkles }
            character
                .offset(y: bounce ? -size * 0.06 : size * 0.03)
        }
        .frame(width: size * 1.6, height: size * 1.3)
        .onAppear { startAnimating() }
        .onChange(of: mood) { _, _ in startAnimating() }
        .onChange(of: reduceMotion) { _, _ in startAnimating() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mood == .celebrating ? "Kukuk kutluyor" : "Kukuk")
    }

    private var character: some View {
        VStack(spacing: -size * 0.06) {
            // Terazi — maskotun hukuk temalı motifi.
            Image(systemName: "scalemass.fill")
                .font(.system(size: size * 0.22, weight: .bold))
                .foregroundStyle(HMGSTheme.Colors.accent)

            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [HMGSTheme.Colors.accent, HMGSTheme.Colors.accent.opacity(0.72)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .frame(width: size, height: size)
                    .shadow(color: HMGSTheme.Colors.accent.opacity(0.35), radius: 10, y: 6)
                eyes
            }
        }
    }

    private var eyes: some View {
        HStack(spacing: size * 0.16) {
            eye
            eye
        }
        .offset(y: -size * 0.02)
    }

    private var eye: some View {
        ZStack {
            Circle().fill(.white).frame(width: size * 0.22, height: size * 0.22)
            Circle().fill(.black).frame(width: size * 0.1, height: size * 0.1)
                .offset(y: mood == .celebrating ? -size * 0.02 : 0)
        }
    }

    private var sparkles: some View {
        ForEach(0..<6, id: \.self) { index in
            Image(systemName: "sparkle")
                .font(.system(size: size * 0.14))
                .foregroundStyle(HMGSTheme.Colors.warning)
                .offset(sparkleOffset(for: index))
                .opacity(sparkle ? 1 : 0)
                .scaleEffect(sparkle ? 1 : 0.4)
        }
    }

    private func sparkleOffset(for index: Int) -> CGSize {
        let angle = Double(index) / 6.0 * 2 * .pi
        let radius = size * 0.62
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius * 0.7 - size * 0.1)
    }

    /// "Hareketi Azalt" açıksa hiçbir animasyon çalışmıyor — sürekli zıplayan bir
    /// karakter, hareket duyarlılığı olan kullanıcı için gerçek bir sorun.
    private func startAnimating() {
        guard !reduceMotion else {
            bounce = false
            sparkle = mood == .celebrating
            return
        }
        switch mood {
        case .idle:
            bounce = false
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                bounce = true
            }
        case .celebrating:
            bounce = false
            sparkle = false
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5).repeatCount(4, autoreverses: true)) {
                bounce = true
            }
            withAnimation(.easeOut(duration: 0.6)) {
                sparkle = true
            }
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        MascotView(mood: .idle)
        MascotView(mood: .celebrating, size: 120)
    }
    .padding()
}
