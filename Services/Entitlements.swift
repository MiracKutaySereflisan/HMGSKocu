// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import Foundation
import Combine

/// "Bu kullanıcı neye erişebiliyor" sorusunun tek cevap yeri.
///
/// **v1 kararı:** Uygulamanın tamamı ücretsiz. Sebebi teknik değil, ticari ve
/// hukuki: satın alınamayan bir paywall ("Premium'a özel" deyip Apple'ın satın alma
/// akışını çağırmamak) App Store Review 3.1.1/2.1 altında red sebebidir; uygulama
/// içi promosyon koduyla ücretli özellik açmak da aynı maddeye girer. İlk sürümü
/// temiz ve tam işlevli çıkarmak, hem onay ihtimalini yükseltiyor hem de ilk
/// kullanıcı kitlesini ve yorumları kazandırıyor.
///
/// **Sonraki sürümde ücretlendirme:** Aşağıdaki `Feature` listesi ve
/// `isUnlocked(_:)` yerinde duruyor. Para modeline geçerken yapılacak tek şey:
/// 1. App Store Connect'te ürünü tanımlamak,
/// 2. `StoreKitPurchaseController`'ı (aşağıdaki iskelet) doldurmak,
/// 3. `plan` değerini StoreKit'ten gelen gerçek hakla beslemek.
/// Ekranların hiçbiri değişmez — hepsi zaten `Entitlements.shared.isUnlocked(...)`
/// soruyor, hiçbir yerde sabit `true` yok.
@MainActor
final class Entitlements: ObservableObject {
    static let shared = Entitlements()

    /// Uygulamada paraya konu OLABİLECEK yetenekler. Şu an hepsi açık; ileride
    /// hangisinin ücretli olacağına burada karar verilecek.
    enum Feature: String, CaseIterable {
        case unlimitedExamLength      // 40'tan uzun denemeler
        case fullSubjectCatalogue     // tüm dersler
        case unlimitedMistakeRetake   // hata havuzunu sınırsız tekrar çözme
        case detailedStatistics       // ayrıntılı istatistikler
    }

    enum Plan: Equatable {
        /// v1: her şey açık.
        case fullAccessFree
        /// İleride: satın alınmış hak.
        case purchased(productID: String)

        var isPaid: Bool {
            if case .purchased = self { return true }
            return false
        }
    }

    @Published private(set) var plan: Plan = .fullAccessFree

    private init() {}

    /// Tek soru noktası. v1'de her zaman true döner; ücretlendirmeye geçildiğinde
    /// yalnızca bu gövde değişir.
    func isUnlocked(_ feature: Feature) -> Bool {
        switch plan {
        case .fullAccessFree:
            return true
        case .purchased:
            return true
        }
    }

    /// Arayüzün "ücretli sürüm var mı" diye sorduğu yer. v1'de false olduğu için
    /// hiçbir ekranda paywall, fiyat ya da "Premium" rozeti görünmüyor — Review
    /// 2.3 (yanıltıcı metadata) açısından da bu doğru olan: olmayan bir ürünü
    /// arayüzde göstermiyoruz.
    var isPaidTierAvailable: Bool { false }
}

/*
 GELECEK SÜRÜM İÇİN İSKELET — v1'de derlemeye dahil değil, bilinçli olarak yorumda.
 StoreKit 2 ile ücretlendirmeye geçerken bu bloğu ayrı bir dosyaya alıp doldur.

 Uygulanacak kurallar (App Store Review 3.1.1 ve 3.1.2):
 - Dijital içerik/abonelik SADECE Apple'ın satın alma akışıyla satılır.
 - Satın alma ekranında fiyat, süre ve yenileme koşulu açıkça yazar.
 - "Satın Alımları Geri Yükle" butonu ZORUNLU.
 - Kullanım Şartları ve Gizlilik Politikası bağlantıları satın alma ekranında bulunur.

 import StoreKit

 @MainActor
 final class StoreKitPurchaseController: ObservableObject {
     static let productIDs = ["com.mirackutay.HMGSKocu.premium.yearly"]

     @Published private(set) var products: [Product] = []
     @Published private(set) var purchasedProductIDs: Set<String> = []

     private var updatesTask: Task<Void, Never>?

     func start() {
         updatesTask = Task { [weak self] in
             for await update in Transaction.updates {
                 await self?.handle(update)
             }
         }
         Task { await refresh() }
     }

     func refresh() async {
         products = (try? await Product.products(for: Self.productIDs)) ?? []
         await refreshEntitlements()
     }

     func purchase(_ product: Product) async throws {
         let result = try await product.purchase()
         if case .success(let verification) = result,
            case .verified(let transaction) = verification {
             await transaction.finish()
             await refreshEntitlements()
         }
     }

     /// "Satın Alımları Geri Yükle" butonunun çağırdığı yer.
     func restore() async throws {
         try await AppStore.sync()
         await refreshEntitlements()
     }

     private func refreshEntitlements() async {
         var owned: Set<String> = []
         for await entitlement in Transaction.currentEntitlements {
             if case .verified(let transaction) = entitlement {
                 owned.insert(transaction.productID)
             }
         }
         purchasedProductIDs = owned
     }

     private func handle(_ update: VerificationResult<Transaction>) async {
         if case .verified(let transaction) = update {
             await transaction.finish()
             await refreshEntitlements()
         }
     }
 }
 */
