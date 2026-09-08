import SwiftUI

/// İlk açılış ekranı: isim + içerik uyarısı, tek ekranda.
///
/// Neden alert değil de tam ekran: eski sürümde isim bir `alert` içinde
/// soruluyordu ve içerik uyarısı hiç yoktu. Uyarıyı kullanıcının gerçekten
/// gördüğü bir yere koymak hem dürüstlük hem de App Store 2.3 (yanıltıcı
/// tanıtım) açısından doğru olan.
///
/// Kayıt duvarı YOK: e-posta, telefon, şifre istenmiyor. İsim bile zorunlu değil —
/// boş bırakılırsa "Hukukçu" olarak devam ediyor.
struct WelcomeView: View {
    var onContinue: (String) -> Void

    @State private var name = ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                MascotView(mood: .idle, size: 96)

                VStack(spacing: 8) {
                    Text("Hoş geldin")
                        .font(.title.bold())
                    Text("Sana nasıl hitap edelim?")
                        .font(.subheadline)
                        .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                }

                TextField("Adın (isteğe bağlı)", text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($nameFocused)
                    .onSubmit { onContinue(name) }
                    .padding()
                    .frame(minHeight: HMGSTheme.Layout.minimumTapTarget)
                    .background(HMGSTheme.Colors.cardBackground, in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.controlCornerRadius, style: .continuous))
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Label {
                        Text(ContentPolicy.shortNotice)
                            .font(.footnote)
                            .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(HMGSTheme.Colors.accent)
                    }

                    Label {
                        Text(ContentPolicy.privacyShort)
                            .font(.footnote)
                            .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "hand.raised.fill")
                            .foregroundStyle(HMGSTheme.Colors.success)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HMGSTheme.Colors.cardBackground, in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.cardCornerRadius, style: .continuous))
                .padding(.horizontal)

                Button {
                    onContinue(name)
                } label: {
                    Text("Başla")
                }
                .buttonStyle(HMGSPrimaryButtonStyle())
                .padding(.horizontal)

                Spacer(minLength: 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
        .scrollDismissesKeyboard(.interactively)
        .hmgsAmbientBackground()
    }
}

#Preview {
    WelcomeView { _ in }
}
