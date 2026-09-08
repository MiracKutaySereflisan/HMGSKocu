// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import Foundation

/// Kullanıcının Profil'den seçtiği görünüm tercihi. UserDefaults'ta
/// "app_appearance" anahtarıyla saklanır (`HMGSKocuApp` ve `ProfileView` aynı
/// `@AppStorage` anahtarını okuyup otomatik senkron kalır).
enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "Sistem"
        case .light: return "Açık"
        case .dark: return "Koyu"
        }
    }
}

/// Uygulama genelinde kullanılan UserDefaults anahtarları. Tek yerde toplu:
/// "Verilerimi Sil" akışının neyi temizleyeceğini bilmesi ve iki farklı dosyada
/// yazım hatasıyla ayrışan anahtarlar olmaması için.
enum DefaultsKey {
    static let appearance = "app_appearance"
    static let displayName = "local_display_name"
    static let hasSeenAppTour = "has_seen_app_tour"
    static let hasAcceptedContentNotice = "has_accepted_content_notice"
    static let dailyGoal = "daily_question_goal"
    static let studyDayStamps = "study_day_stamps"

    static let all: [String] = [
        appearance, displayName, hasSeenAppTour,
        hasAcceptedContentNotice, dailyGoal, studyDayStamps
    ]
}

/// Günlük soru hedefi. Ana sayfadaki halkanın neye göre dolduğu tek yerde tanımlı;
/// kullanıcı Profil'den değiştirebiliyor.
enum DailyGoal {
    static let options = [10, 20, 30, 50, 100]
    static let fallback = 20

    static func normalized(_ value: Int) -> Int {
        options.contains(value) ? value : fallback
    }
}

/// Uygulama kimliği ve iletişim bilgileri. App Store Connect'e girilen destek
/// adresiyle burasının AYNI olması gerekiyor — kullanıcı uygulamadan yazdığında
/// e-posta buraya düşer.
enum AppInfo {
    static let displayName = "HMGS Koçu"

    /// Destek ve soru hatası bildirimi için e-posta. App Store Connect'teki
    /// "Support URL" ve buradaki adres tutarlı olmalı.
    static let supportEmail = "destek@hmgskocu.app"

    /// Gizlilik politikasının yayınlandığı adres. App Store'a göndermeden ÖNCE
    /// gerçek bir URL ile değiştirilmelidir.
    static let privacyPolicyURL = URL(string: "https://hmgskocu.app/gizlilik")

    static var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}

/// Soru içeriğinin ne olduğu ve ne OLMADIĞI konusundaki resmî uygulama metni.
/// Tek bir yerde duruyor ki uygulama içindeki uyarı, App Store açıklaması ve
/// gizlilik politikası birbiriyle çelişmesin — çelişki hem yanıltıcı metadata
/// (Review 2.3) hem de tüketici hukuku açısından risk.
enum ContentPolicy {
    static let shortNotice =
        "Bu uygulamadaki sorular HMGS'ye hazırlık için özel olarak hazırlanmış çalışma sorularıdır; " +
        "resmî çıkmış sınav soruları değildir."

    static let longNotice = """
    HMGS Koçu'ndaki sorular, HMGS müfredatındaki konu başlıklarına göre bu uygulama için \
    özel olarak hazırlanmış, ilgili kanun maddesine referans verilerek yazılmış çalışma \
    sorularıdır. Her sorunun altında dayandığı madde açıkça yazılıdır.

    Bu sorular resmî HMGS çıkmış soruları DEĞİLDİR ve öyle sunulmaz. Soru metinleri ve \
    şıklar özgündür; herhangi bir yayınevinin, kurumun ya da sınav sorumlusunun \
    materyalinden alınmamıştır.

    Mevzuat sık değişir. Bir soruda hata, eskimiş bir madde ya da tartışmalı bir cevap \
    gördüğünde, sorunun altındaki "Bu soruda hata var" bağlantısıyla bize bildir — \
    bildirimler tek tek incelenip düzeltiliyor.

    Bu uygulama hukuki danışmanlık vermez; içerik yalnızca sınav hazırlığı amaçlıdır.
    """

    static let privacyShort =
        "HMGS Koçu hiçbir veri toplamaz. İlerlemen yalnızca senin cihazında saklanır, " +
        "hiçbir sunucuya gönderilmez, hesap açman gerekmez."
}
