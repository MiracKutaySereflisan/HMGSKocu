# Lisans ve Telif Envanteri

**İlke:** Projeye giren her parça ya kendi ürettiğimiz ya da ticari kullanıma
açıkça izin veren bir lisansla gelmiş olacak. Şüpheliyse alınmıyor.

## Kod bağımlılıkları

**Yok.** Uygulama sıfır üçüncü taraf paket kullanıyor — Swift Package Manager'da
hiçbir bağımlılık tanımlı değil.

Bunun getirdikleri: uygulama içinde "Açık Kaynak Lisansları" ekranı gerekmiyor,
hiçbir SDK'nın gizlilik beyanını (privacy manifest) takip etmek zorunda değiliz,
GPL/AGPL bulaşma riski yok, bir kütüphanenin bakımsız kalması riski yok.

Kullanılan her şey Apple'ın kendi çatıları: SwiftUI, Foundation, Combine, UIKit
(yalnızca haptik için), os (günlük), XCTest (testler).

## Görseller ve simgeler

| Varlık | Kaynak | Lisans / durum |
|---|---|---|
| `AppIcon-1024.png` | Proje için üretilmiş terazi + dolma kalem tasarımı; bu sürümde alfa kanalı kaldırılıp tam kareye tamamlandı | Projeye ait. **Kontrol et:** Bu görseli bir yapay zekâ aracıyla ürettiysen o aracın ticari kullanım şartlarını doğrula ve bu satıra yaz. |
| `SplashLogo.png` | Aynı tasarımın 512 px'e küçültülmüş, saydamlığı korunmuş hâli | Aynı |
| Arayüzdeki tüm simgeler | Apple **SF Symbols** | Apple platformlarında serbest. Kural: SF Symbols bir sembolü değiştirip marka/logo yapmak yasak — yapılmıyor. |
| Maskot "Kukuk" | `Views/Journey/MascotView.swift` içinde kodla çiziliyor | Projeye ait, hiçbir dosya bağımlılığı yok |

## Yazı tipleri

Yalnızca sistem fontu (San Francisco) kullanılıyor, Dynamic Type ile.
Hiçbir harici font paketlenmiyor.

## Metinler

| İçerik | Durum |
|---|---|
| 679 soru, şık ve açıklama | Bu proje için hazırlandı. Herhangi bir yayınevinin, kursun ya da sınav kurumunun materyalinden alınmadı; resmî çıkmış sorular değil. |
| Kanun maddesi atıfları (TMK m. 28 gibi) | Kanun metinleri kamuya açıktır; atıf yapmak telif konusu değildir. Maddelerin uzun uzun kopyalanmasından kaçınılıyor, açıklamalar özetleyerek yazılıyor. |
| Açılış ekranı özdeyişleri (`LawQuote`) | Kamuya mal olmuş, yaygın olarak aktarılan hukuk özdeyişleri ve Latin maksimleri. Yaşayan bir yazarın telifli metni, şarkı sözü ya da kitap pasajı **yok**. |
| Arayüz metinleri | Bu proje için yazıldı |

## Marka

"HMGS", bir sınavın kısaltması olarak tanımlayıcı biçimde kullanılıyor
(uygulamanın neye hazırladığını anlatmak için). Uygulama adı "HMGS Koçu"; herhangi
bir resmî kurumun logosu, arması, adı ya da onayı kullanılmıyor ve kullanıcıda
resmî bir bağ izlenimi yaratacak hiçbir ifade yok.

**Yapılmayacaklar:** Adalet Bakanlığı, ÖSYM ya da herhangi bir kurumun logosunu,
armasını, tipografisini kullanmak; "resmî", "onaylı", "Bakanlık destekli" gibi
ifadeler; başka bir hazırlık uygulamasının ekran görüntüsü ya da tasarımı.

## Yasal dayanak — mevzuat metinlerinin kullanımı

**FSEK m. 31** (5846 sayılı Kanun, yürürlükteki metin):

> "Resmen yayımlanan veya ilân olunan kanun, Cumhurbaşkanlığı kararnamesi,
> yönetmelik, tebliğ, genelge ve kazai kararların çoğaltılması, yayılması,
> işlenmesi veya her hangi bir suretle bunlardan faydalanma serbesttir."

Bu hüküm, uygulamanın içerik üretiminin dayanağıdır: kanun metinlerinden soru
üretmek, maddeye atıf yapmak ve kısa alıntılamak serbesttir.

**Ancak kanun serbesttir, kanun ÜZERİNE yazılmış olan değildir.** Yayınevi
şerhleri, açıklamalı-içtihatlı basımlar, kurs soru bankaları, akademik kitap ve
makaleler telifli eserdir; bunlardan alıntı yapılmaz, "yeniden yazılarak"
kullanılmaz. Soru maddeden üretilir, başka sorudan değil.

## Onay ve akreditasyon iddiası — yok, iddia da edilmez

Millî Eğitim Bakanlığı Talim ve Terbiye Kurulu, kendi SSS sayfasında, Bakanlıkça
temin edilip ücretsiz dağıtılan ders kitapları ve eğitim araçları dışında özel
yayınevlerinin piyasaya sürdüğü kaynakların incelenmesinin Kurulun görev ve
yetki alanında olmadığını belirtiyor. Yetişkinlere yönelik, örgün eğitim dışı bir
sınav hazırlık uygulaması için alınacak bir MEB onayı ne gerekli ne mümkündür.

Bu yüzden uygulama metinlerinde **"MEB onaylı", "Bakanlık destekli", "resmî",
"akredite" ifadeleri kullanılmaz.** Olmayan bir onayı iddia etmek hem yanıltıcı
reklamdır hem de App Store Review 2.3 kapsamında kaldırılma sebebidir.

HMGS'yi düzenleyen kurumların adı, logosu ve arması kullanılmaz; "HMGS" yalnızca
uygulamanın neye hazırladığını anlatan tanımlayıcı bir ifadedir.

## Bu dosya ne zaman güncellenir

Projeye yeni bir görsel, font, ses, kütüphane ya da metin girdiği **anda**. Kaynağı
ve lisansı yazılmayan hiçbir varlık projeye girmez.
