import SwiftUI
import UIKit

/// Dokunsal geri bildirim. Kural: yalnızca ANLAM taşıdığı yerde kullanılır
/// (aşama geçildi, kayıt silindi, süre doldu) — süs olarak değil. Kullanıcı
/// "Titreşimi Azalt" ayarını açtıysa sistem zaten sessizleştirir.
enum Haptics {
    @MainActor
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @MainActor
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    @MainActor
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

/// Kullanıcının bir soruda hata bildirmesi ya da destek yazması için hazırlanan
/// e-posta bağlantıları.
///
/// Neden `mailto:` ve sunucu değil: uygulama hiçbir veri toplamıyor. Bildirimi
/// kullanıcının kendi e-posta uygulaması üzerinden göndermesi, "arka planda bize
/// veri gidiyor" durumunu tamamen ortadan kaldırıyor — gizlilik etiketimiz
/// "Veri Toplanmıyor" olarak kalabiliyor ve kullanıcı ne gönderdiğini gözüyle görüyor.
enum FeedbackComposer {

    /// Bir soruyla ilgili hata bildirimi taslağı.
    static func reportQuestionURL(question: Question) -> URL? {
        let subject = "HMGS Koçu — Soru bildirimi (\(question.subject.displayName))"
        let body = """
        Merhaba,

        Aşağıdaki soruda bir sorun olduğunu düşünüyorum:

        Soru kodu: \(question.id.uuidString)
        Ders: \(question.subject.displayName)
        Konu: \(question.topicTag)
        Madde referansı: \(question.lawReference ?? "—")

        Sorun ne? (aşağıya yazabilirsin)
        - [ ] Cevap yanlış görünüyor
        - [ ] Madde referansı hatalı/eskimiş
        - [ ] Soru metninde yazım hatası var
        - [ ] Birden fazla şık doğru
        - [ ] Diğer:


        Uygulama sürümü: \(AppInfo.versionString)
        """
        return mailURL(subject: subject, body: body)
    }

    /// Genel destek/öneri taslağı.
    static func supportURL() -> URL? {
        let subject = "HMGS Koçu — Destek / öneri"
        let body = """
        Merhaba,


        (Yazmak istediğini buraya ekleyebilirsin.)

        Uygulama sürümü: \(AppInfo.versionString)
        """
        return mailURL(subject: subject, body: body)
    }

    private static func mailURL(subject: String, body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppInfo.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        // URLComponents boşlukları "%20", satır sonlarını "%0A" olarak kodluyor —
        // mailto için doğru olan bu. Elle "+" dönüşümü YAPILMIYOR, çünkü mailto
        // gövdesinde "+" gerçek bir artı işareti olarak okunur.
        guard let string = components.string else { return nil }
        return URL(string: string)
    }
}
