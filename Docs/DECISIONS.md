# Kararlar Günlüğü

Her satır: tarih · karar · gerekçe · elenen alternatif neden elendi.

---

## 2026-08-15 — v1 ücretsiz çıkacak, ücretlendirme altyapısı hazır bekleyecek

**Karar.** Uygulamanın tamamı ücretsiz. Paywall ekranı, "Premium Üye" rozeti ve
promosyon kodu alanı kaldırıldı. Yerine `Services/Entitlements.swift` kondu: tek
soru noktası (`isUnlocked(_:)`), StoreKit 2 iskeleti yorumda hazır.

**Gerekçe.** Eski kodda satın alınamayan bir paywall vardı: 40 soruyu geçince
"Premium'a özel" deyip Apple'ın satın alma akışını çağırmıyor, kullanıcıyı bir
promosyon kodu alanına yönlendiriyordu. Bu, App Store Review 3.1.1 (dijital
içeriğin IAP dışında açılması) ve 2.1 (çalışmayan özellik) altında doğrudan red
sebebi. İlk sürümü temiz ve tam işlevli çıkarmak onay ihtimalini yükseltiyor, ilk
kullanıcıları ve yorumları kazandırıyor.

**Elenen alternatif.** Hemen StoreKit 2 aboneliği kurmak: App Store Connect'te ürün
tanımı, Paid Apps sözleşmesi ve banka/vergi bilgisi tamamlanmadan ürünler yüklenmez;
tamamlanmadan gönderilirse reviewer satın alamaz ve 2.1'den red gelir. Fiyat kararı
da kullanıcı sayısı görülmeden verilirse yanlış verilir.

**Geri dönüş maliyeti.** Düşük: ekranların hiçbiri değişmeyecek, `Entitlements`
gövdesi ve bir satın alma ekranı eklenecek. Yarım günlük iş.

---

## 2026-08-15 — Minimum iOS 26.0 → 17.0

**Karar.** `IPHONEOS_DEPLOYMENT_TARGET = 17.0`.

**Gerekçe.** Proje iOS 26.0 hedefliyordu; bu, cihazların yalnızca en yeni iOS'a
geçmiş küçük bir kısmının indirebilmesi demek. Koddaki en yeni API'ler
(`ContentUnavailableView`, `navigationDestination(item:)`, iki parametreli
`onChange`) iOS 17'de mevcut, yani hiçbir özellikten ödün vermeden kitle kat kat
büyüyor. Yapının Xcode 26 / iOS 26 SDK ile DERLENMESİ zorunluluğu (28 Nisan
2026'dan beri) ayrı bir şey ve devam ediyor — deployment target daha düşük olabilir.

**Elenen alternatif.** iOS 18: yeni SwiftUI API'leri serbest kalırdı ama şu an
hiçbirine ihtiyaç yok; karşılığında kitle daralırdı.

**Dikkat.** `count(where:)` gibi Swift 6 standart kütüphanesi eklemeleri iOS 18
gerektirir; kod tabanında bilinçli olarak kullanılmıyor (`filter{}.count` tercih
edildi) ve statik denetim bunu kontrol ediyor.

---

## 2026-08-15 — Veri tamamen cihazda, hesap yok

**Karar.** Supabase bağlanmadı; `SupabaseService` adı `AppDataStore` oldu.
Kayıt/giriş yok, sunucu yok, analitik yok. Gizlilik etiketi "Veri Toplanmıyor".

**Gerekçe.** Toplanmayan veri sızmaz, beyan edilmez, dava konusu olmaz. KVKK/GDPR
yükümlülüğü minimuma iner, hesap silme akışı zorunluluğu doğmaz (Review 5.1.1(v)
hesap açtıran uygulamalar için geçerli), inceleme süresi kısalır, sunucu maliyeti
sıfır olur. Kullanıcı açısından da fark yok: HMGS çalışması tek cihazda yapılır.

**Elenen alternatif.** Supabase ile hesap + senkron: cihaz değişiminde veri taşıma
kazandırırdı ama gizlilik politikası, hesap silme akışı, veri işleme sorumluluğu,
aylık maliyet ve daha uzun inceleme getirirdi. Cihaz değişimi ihtiyacı iCloud
yedeğiyle zaten büyük ölçüde karşılanıyor (dosyalar `Documents` altında tutuluyor,
bu klasör iCloud yedeğine dahil).

**Geri dönüş maliyeti.** Orta: `AppDataStore` arayüzü aynı kaldığı için sunucu
eklemek tek dosyayı değiştirmek demek, ama göç ve gizlilik beyanı işi eklenir.

---

## 2026-08-15 — iPhone-only (TARGETED_DEVICE_FAMILY = 1)

**Karar.** iPad desteği v1'de kapatıldı; yalnızca dikey (portrait) yön.

**Gerekçe.** iPad'i desteklediğini beyan eden bir uygulama, iPad ekran
görüntülerini de vermek ve iPad'de düzgün görünmek zorunda (Review 2.3 ve 4.0).
Yolculuk haritası ve kart ızgaraları iPad genişliğinde seyrek duruyordu. Kullanım
anı da telefon: yolda, tek elle. iPad kullanıcıları uygulamayı yine uyumluluk
modunda indirebiliyor.

**Elenen alternatif.** iPad'i düzgün desteklemek: gerçek bir uyarlama işi (en az
2-3 gün) ve v1'i geciktirir. Sonraki sürüme bırakıldı.

---

## 2026-08-15 — Yarım kalan sınav diske yazılıyor

**Karar.** Her cevapta ve her soru geçişinde `InProgressExam` diske yazılıyor;
ana sayfada "Kaldığın yerden devam et" kartı çıkıyor. 24 saatten eski kayıt
teklif edilmiyor.

**Gerekçe.** 120 soruluk bir denemenin ortasında telefon çalarsa, iOS uygulamayı
bellekten atarsa ya da kullanıcı yanlışlıkla çıkarsa eski kodda 40 dakikalık emek
tamamen kayboluyordu. Bu, kötü yorumların en klasik kaynağı.

**Elenen alternatif.** Sadece bellekte tutmak (eski davranış): basit ama veri
kaybı. Otomatik devam ettirmek (sormadan): kullanıcı bilerek çıkmış olabilir.

---

## 2026-08-15 — Soruların doğru şıkkı yeniden dağıtıldı

**Karar.** 679 sorunun şık sıraları, doğru cevap A-B-C-D-E arasında eşit dağılacak
şekilde yeniden düzenlendi (her harf ~%20). Soru metinleri, şık metinleri ve doğru
cevaplar **değişmedi**; sadece sıra değişti ve `correctOptionIndex` buna göre
güncellendi. Dönüşüm, doğru şık metninin aynı kaldığı ve şık kümesinin
korunduğu programatik olarak doğrulanarak yapıldı.

**Gerekçe.** Eskiden B şıkkı %24,7, A şıkkı %18,2 oranındaydı. Bir kullanıcı bunu
fark ederse soruyu okumadan tahmin etmeye başlar; bu hem çalışma değerini düşürür
hem de uygulamanın ciddiyetine zarar verir.

---

## 2026-08-15 — Sınav başlatma tek kanala indirildi (`ExamLaunch`)

**Karar.** Dört ekran da `.examDestination($launch)` kullanıyor.

**Gerekçe.** Ana sayfada aynı tipte (`ExamConfiguration`) iki ayrı
`navigationDestination(item:)` vardı; SwiftUI'da aynı tip için ikinci hedef
sessizce çalışmaz — "kaldığın yerden devam et" hiç açılmazdı. Ayrıca hata
havuzunda soru listesi ve yapılandırma iki ayrı `@State` olarak sırayla
atanıyordu; yanlış sırada atanırsa boş listeyle sınav başlayabiliyordu. Tek paket
her ikisini de yapısal olarak imkânsız kılıyor.

---

## 2026-08-15 — App Store ikonu yeniden üretildi

**Karar.** İkondaki alfa kanalı kaldırıldı, gömülü yuvarlak köşeler tam kareye
tamamlandı.

**Gerekçe.** Mevcut ikon 1024×1024 RGBA idi ve köşeleri saydamdı. App Store
Connect bu yapıyı `ITMS-90717 Invalid App Store Icon` hatasıyla reddediyor —
yükleme daha doğrulama aşamasında düşerdi. Ayrıca iOS ikona kendi maskesini
uyguladığı için gömülü yuvarlak köşe "çift köşe" görünümü yaratıyordu.

---

## 2026-08-15 (aynı gün, ikinci tur) — `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` kaldırıldı

**Karar.** Bu derleme ayarı hem uygulama hem test hedefinden çıkarıldı.
`SWIFT_APPROACHABLE_CONCURRENCY = YES` yerinde kaldı.

**Gerekçe.** Xcode 26'nın yeni proje şablonu bu ayarı varsayılan koyuyor: izolasyonu
açıkça yazılmamış HER tip ana iş parçacığına (MainActor) bağlanıyor. Bu, ekran
kodunu yazarken kolaylık; ama bizim mimarimizde `LocalStore` ve
`SeedQuestionLoader` gibi saf, ekranla ilgisi olmayan tipler de MainActor'a
bağlanmış oluyordu. Disk işlerini ana iş parçacığından çıkarmak için kurduğumuz
`PersistenceActor` bu tipleri çağırdığında derleyici 15 uyarı üretti:
*"Call to main actor-isolated static method in a synchronous actor-isolated context"*.

Bu uyarılar susturulacak değil, çözülecek cinsten: Swift 6 dil moduna geçildiğinde
HATA olacaklar ve daha önemlisi doğru olanı söylüyorlar — bir dosya okuma
fonksiyonunun ana iş parçacığına bağlı olması için hiçbir sebep yok.

**Ne değişti sonuçta.** Saf tipler (modeller, motorlar, kalıcılık) artık
izolasyonsuz; ekran katmanı ise zaten SwiftUI'ın `View`/`App` protokolleri
üzerinden MainActor'da, ViewModel'lar ve `AppDataStore` da açıkça `@MainActor`
işaretli. Yani izolasyon artık *tesadüfen* değil, *bilinçli* olarak nerede
gerekiyorsa orada.

**Elenen alternatif.** Ayarı bırakıp uyarı veren her üyeye tek tek `nonisolated`
yazmak: aynı sonucu 40+ satır gürültüyle verirdi ve bir sonraki saf tip
eklendiğinde aynı iş baştan yapılırdı.

**Beraberinde gelen düzeltmeler:**
- `TimerEngine`: Timer geri çağrısı artık her tikte bir `Task` açmak yerine
  `MainActor.assumeIsolated` kullanıyor (timer zaten `RunLoop.main`'e ekli).
  `format` ve `accessibilityText` `nonisolated` yapıldı — testlerden çağrılıyorlar.
- `SplashView`: `DispatchQueue.main.asyncAfter` yerine `.task` + `Task.sleep`.
  Yan fayda: ekran kapanırsa iş iptal oluyor, öksüz geri çağrı kalmıyor.
- `JSONEncoder.hmgs` / `JSONDecoder.hmgs`: paylaşılan `static let` yerine her
  erişimde yeni örnek üreten `static var`. Bu tipler `Sendable` değil; paylaşılan
  tek örnek farklı iş parçacıklarından kullanılırsa sessiz veri bozulması riski var.
- İki `DateFormatter` (`Format.sessionDate`, `StreakCalculator.formatter`):
  `nonisolated(unsafe) static let` + neden güvenli olduğunu anlatan yorum
  (oluşturulduktan sonra değiştirilmiyor, yalnızca okunuyor).
- `View.examDestination`: `@MainActor` açıkça yazıldı (içinde MainActor ViewModel kuruluyor).

## 2026-08-16 — Kurtarmalı okuma + hata şiddeti ayrımı

**Karar.** Diskteki liste dosyaları (`exam_sessions.json`, `question_stats.json`,
`unlocked_achievements.json`) artık kayıt kayıt okunuyor: okunamayan tek bir kayıt
atılıyor, geri kalanı korunuyor ve dosya bir kez temiz hâliyle geri yazılıyor.
Ayrıca `StoreError.isUserActionable` eklendi; sınav sonunda **yalnızca yazma**
hataları kullanıcıya gösteriliyor, okuma hataları günlüğe düşüyor.

**Gerekçe.** Test kullanıcısından gelen geri bildirim: her aşama sonunda
"Kayıtlı ilerlemen okunamadı. Uygulamayı kapatıp açmayı dene." uyarısı çıkıyor,
uygulamayı kapatıp açmak da çözmüyor. Sebep yapısaldı — tek bir eski/bozuk kayıt
dosyanın tamamını okunamaz yapıyordu ve kalıcı olduğu için her sınavda tekrar
ediyordu. Gösterilen metin de yanlıştı: önerdiği eylem sorunu çözmüyordu.

**Elenen alternatifler.**
- *Uyarıyı kaldırmak:* belirtiyi gizler, sebebi durur. Yazma hatasında kullanıcının
  gerçekten yapabileceği bir şey var (yer açmak); onu da susturmak olurdu.
- *Bozuk dosyayı silip sıfırlamak:* tek bir kayıt yüzünden tüm geçmişi silmek,
  çözmeye çalıştığımız veri kaybının daha büyüğü olurdu.
- *Her modele ayrı göç kodu yazmak:* zaten yazılmış; asıl sorun ileride eklenecek
  her alanın aynı riski taşıması. Kurtarmalı okuma bu sınıfı bir kez kapatıyor.

**Geri dönüş maliyeti.** Düşük — üç `load` fonksiyonu ve tek `catch` bloğu.
