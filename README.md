# HMGS Koçu

HMGS'ye (Hukuk Mesleklerine Giriş Sınavı) hazırlanan hukuk mezunları için iOS
çalışma uygulaması. Hesap yok, sunucu yok, reklam yok — her şey cihazda çalışır.

**Min iOS:** 17.0 · **Bağımlılık:** yok · SwiftUI

## Ne yapıyor

- **Gerçek sınav parametreleriyle deneme.** 120 soru, 155 dakika, gerçek ders
  dağılımı; soru başına kalan süre otomatik hesaplanır. Tek ders çalışma ve
  süresiz mod da var.
- **Kalıcı hata havuzu.** Yanlış cevaplanan sorular derse göre gruplanır, tekrar
  çözülür; doğruya çevrilenler ayrıca takip edilir.
- **Yolculuk modu.** Her ders, sekizerli aşamalara bölünür ve aşama aşama açılır.
- **Çevrimdışı.** Soru bankası cihazda; uygulama internet bağlantısı istemez.
- Ders bazlı ilerleme, gösterge paneli, rozetler.

## Soru bankası hakkında

Sorular resmî mevzuat metinleri kaynak alınarak üretildi; çıkmış sınav sorusu
değildir ve öyle olduğu iddia edilmez (bir test bunu ayrıca doğrular). Her sorunun
dayandığı kanun maddesi kayıtlıdır ve açıklamasının o maddeye değinmesi test
kapısından geçmenin şartıdır.

Üretim yöntemi ve kaynak kaydı:
`Docs/SORU_URETIM_PROTOKOLU.md` · `Docs/SORU_KAYNAK_KAYDI.md`

> **Bu depoda örnek havuz vardır.** Yayımlanan sürüm 24 dersin her birinden 3 soru
> içerir (72 soru). Uygulamanın tamamı bu havuzla derlenir ve çalışır. Tam havuzu
> gerektiren testler (120 soruluk deneme, Yolculuk aşama üretimi ve ders başına alt
> sınır) örnek havuzda otomatik olarak atlanır; tam havuzla koşulduğunda çalışırlar.

## Yapı

| Klasör | İçinde ne var |
|---|---|
| `Models/` | Soru, ders, ilerleme ve ayar modelleri |
| `Services/` | Veri saklama, soru yükleme, günlükleme |
| `ViewModels/` | Sınav akışı, seçim ve puanlama mantığı |
| `Views/` | Arayüz ve tema |
| `Resources/` | Soru havuzu, varlıklar, gizlilik bildirimi |
| `Tools/` | `soru_denetim.py` — yeni soru partilerini standarda karşı denetleyen kapı |
| `HMGSKocuTests/` | Motor, içerik kalitesi ve kurtarmalı okuma testleri |
| `Docs/` | Proje özeti, kararlar, lisans envanteri, gizlilik metni, üretim protokolü |

## Çalıştırma

```
HMGSKocu.xcodeproj → aç
⌘B   derle
⌘U   testleri koştur
⌘R   simülatörde çalıştır
```

## Testler üzerine

Testler iki ayrı soruyu ayırır: bir soru **bozuk** mu (5 şık var mı, indeks geçerli
mi, id tekrar ediyor mu) ve bir soru **iyi** mi (açıklama öğretiyor mu, dayanağı
yazılı mı, doğru cevap şıkkın uzunluğundan tahmin edilebiliyor mu).

`LossyReadTests` gerçek bir kullanıcı şikâyetinden doğdu: kayıt dosyasındaki tek bir
okunamayan satır, dosyanın tamamını okunamaz yapıyordu. O davranışın geri gelmesini
bu testler engelliyor.

## Telif

Tüm hakları saklıdır. Kod incelenmek üzere paylaşılmıştır.
Üçüncü taraf içerik envanteri: `Docs/LICENSES.md`.
