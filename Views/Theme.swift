// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import SwiftUI
import UIKit   // yalnızca renklerin Açık/Koyu moda göre otomatik değişmesi için

/// HMGS Koçu'nun tasarım sistemi.
///
/// İlke: Apple Human Interface Guidelines temel, kişilik onun üstüne kuruluyor.
/// Renkler ve tipografi Apple'ın **semantik** değerlerine dayanıyor (ham hex yok) —
/// böylece Açık/Koyu mod ve Dynamic Type ekstra iş yapmadan doğru çalışıyor.
enum HMGSTheme {

    // MARK: - Renkler

    enum Colors {
        /// Ana ekran arka planı.
        static let background = Color(uiColor: .systemBackground)
        /// Kart / gruplanmış içerik arka planı — hiyerarşiyi çizgiyle değil
        /// arka plan kontrastıyla kurmak için.
        static let cardBackground = Color(uiColor: .secondarySystemBackground)
        /// Üçüncü katman: iç içe kartlar ve ince dolgular.
        static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)

        /// Marka rengi. Asset Catalog'daki `AccentColor` ile AYNI değer — sistem
        /// kontrolleri (Toggle, bağlantılar, sekme seçimi) oradan alıyor, kodla
        /// çizilen yüzeyler de aynı rengi kullanınca ekranlar birbirinden ayrışmıyor.
        ///
        /// Açık modda koyu bir indigo (#4A47C7), koyu modda açık bir indigo
        /// (#7E7BF2) — çünkü koyu modda marka rengi bir de METİN/simge rengi
        /// olarak siyah zemin üzerinde kullanılıyor ve orada okunabilir olması
        /// gerekiyor (ölçülen kontrast 6.0:1).
        static let accent = Color("AccentColor")

        /// Marka renginin ÜZERİNE yazılan metin/simge rengi.
        ///
        /// Neden sabit beyaz değil: koyu moddaki açık indigo zemin üzerinde beyaz
        /// metnin kontrastı 3.5:1 çıkıyor — WCAG AA'nın normal metin için istediği
        /// 4.5:1'in altında. Aynı zeminde koyu metin 6.0:1 veriyor. Bu yüzden
        /// üstteki metin, arkasındaki tona göre otomatik seçiliyor:
        /// açık modda beyaz (6.97:1), koyu modda neredeyse siyah (6.0:1).
        static let onAccent = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.07, alpha: 1)
                : UIColor.white
        })

        static let label = Color(uiColor: .label)
        static let secondaryLabel = Color(uiColor: .secondaryLabel)
        static let tertiaryLabel = Color(uiColor: .tertiaryLabel)

        /// Anlam taşıyan geri bildirim renkleri — sistemin kendi renkleri
        /// kullanılıyor ki "yeşil = doğru, kırmızı = yanlış" beklentisi bozulmasın.
        static let success = Color(uiColor: .systemGreen)
        static let destructive = Color(uiColor: .systemRed)
        static let warning = Color(uiColor: .systemOrange)

        static let separator = Color(uiColor: .separator)
    }

    // MARK: - Tipografi

    enum Typography {
        /// Soru ve kanun metni. Hukuk metinleri "kelime duvarı" oluşturmaya
        /// müsait; geniş satır aralığı gözün satırı takip etmesini kolaylaştırıyor.
        static let questionText = Font.body
        static let questionLineSpacing: CGFloat = 6

        static let optionText = Font.callout
        /// Madde referansları (TMK m. 705) — rakamlar hizalı dursun diye monospacedDigit.
        static let lawReference = Font.caption.monospacedDigit()
        static let headline = Font.system(.title3, design: .default, weight: .bold)
        static let caption = Font.caption
    }

    // MARK: - Ölçüler

    enum Layout {
        static let cardCornerRadius: CGFloat = 16
        static let controlCornerRadius: CGFloat = 12

        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 20
        static let optionSpacing: CGFloat = 10

        /// Apple HIG'in asgari dokunma hedefi. Kod içinde 44 sabiti serpiştirmek
        /// yerine tek yerden okunuyor ki bir gün değişirse hepsi değişsin.
        static let minimumTapTarget: CGFloat = 44

        static let cardShadowRadius: CGFloat = 12
        static let cardShadowOpacity: Double = 0.06
    }

    // MARK: - Hareket

    enum Motion {
        static let standard = Animation.easeInOut(duration: 0.25)
        static let quick = Animation.easeOut(duration: 0.18)

        /// Kullanıcı "Hareketi Azalt" dediyse animasyonu tamamen kapat.
        static func respectingReduceMotion(_ reduceMotion: Bool, _ animation: Animation) -> Animation? {
            reduceMotion ? nil : animation
        }
    }
}

// MARK: - Yeniden kullanılabilir görünüm biçimleri

/// Uygulamanın standart kart yüzeyi.
struct HMGSCardStyle: ViewModifier {
    var padding: CGFloat = HMGSTheme.Layout.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                HMGSTheme.Colors.cardBackground,
                in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.cardCornerRadius, style: .continuous)
            )
            .shadow(
                color: .black.opacity(HMGSTheme.Layout.cardShadowOpacity),
                radius: HMGSTheme.Layout.cardShadowRadius,
                y: 4
            )
    }
}

struct HMGSQuestionTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(HMGSTheme.Typography.questionText)
            .lineSpacing(HMGSTheme.Typography.questionLineSpacing)
            .foregroundStyle(HMGSTheme.Colors.label)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Form'un büyük harfli bölüm başlıklarının tema uyumlu karşılığı.
///
/// `uppercased()` Türkçe'de HATALIDIR: "İçerik" → "ICERIK" olur, "İÇERİK" olmaz.
/// Bu yüzden her yerde Türkçe yerel ayarıyla büyütülüyor.
struct HMGSSectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text.uppercased(with: Locale.turkish))
            .font(.caption.weight(.semibold))
            .foregroundStyle(HMGSTheme.Colors.secondaryLabel)
            .padding(.leading, 4)
            // VoiceOver büyük harfleri harf harf okumasın diye orijinal metin.
            .accessibilityLabel(text)
    }
}

/// Uygulamanın birincil eylem butonu. Tek yerde durduğu için her ekranda aynı
/// yükseklik, aynı köşe, aynı dokunma hedefi ve aynı devre dışı görünümü var.
struct HMGSPrimaryButtonStyle: ButtonStyle {
    var tint: Color = HMGSTheme.Colors.accent
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(HMGSTheme.Colors.onAccent)
            .frame(maxWidth: .infinity)
            .frame(minHeight: HMGSTheme.Layout.minimumTapTarget)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                tint.opacity(isEnabled ? 1 : 0.4),
                in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.controlCornerRadius, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(HMGSTheme.Motion.quick, value: configuration.isPressed)
    }
}

/// İkincil (çerçeveli) eylem butonu.
struct HMGSSecondaryButtonStyle: ButtonStyle {
    var tint: Color = HMGSTheme.Colors.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(minHeight: HMGSTheme.Layout.minimumTapTarget)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: HMGSTheme.Layout.controlCornerRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension View {
    func hmgsCard(padding: CGFloat = HMGSTheme.Layout.cardPadding) -> some View {
        modifier(HMGSCardStyle(padding: padding))
    }

    func hmgsQuestionTextStyle() -> some View {
        modifier(HMGSQuestionTextStyle())
    }

    /// Düz sistem arka planı yerine çok hafif bir marka rengi yıkaması — "başka bir
    /// yere girdim" hissinin en ucuz parçası. Her ana sekme aynı atmosferi
    /// paylaşıyor, sadece içerik değişiyor.
    func hmgsAmbientBackground() -> some View {
        background(
            LinearGradient(
                colors: [HMGSTheme.Colors.accent.opacity(0.13), HMGSTheme.Colors.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    /// Küçük bir simge/etiket dokunulabilir olduğunda asgari 44×44 pt alan garantisi.
    func hmgsTapTarget() -> some View {
        frame(minWidth: HMGSTheme.Layout.minimumTapTarget, minHeight: HMGSTheme.Layout.minimumTapTarget)
            .contentShape(Rectangle())
    }
}

/// Yüzde gösterimini tek yerden üretir — "%\(Int(x*100))" kalıbı beş ekrana
/// dağılmış durumdaydı ve yuvarlama davranışı her birinde farklıydı.
enum Format {
    static func percent(_ ratio: Double) -> String {
        let clamped = min(max(ratio, 0), 1)
        return "%\(Int((clamped * 100).rounded()))"
    }

    static func duration(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 { return "\(hours) sa \(minutes) dk" }
        if minutes > 0 { return "\(minutes) dk \(secs) sn" }
        return "\(secs) sn"
    }

    /// Tek örnek — bkz. `StreakCalculator.formatter`. Oluşturulduktan sonra
    /// değiştirilmiyor, yalnızca okunuyor.
    static let sessionDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.turkish
        formatter.dateFormat = "d MMMM, HH:mm"
        return formatter
    }()
}
