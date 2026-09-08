# Soru Kaynak Kaydı (ledger)

Her partinin künyesi. **Bir kanun değiştiğinde "hangi sorularım etkilendi"
sorusunun cevabı burasıdır.**

Bu bilgi bilinçli olarak uygulamanın veri şemasına değil bu belgeye yazılıyor:
soru kaydına yeni alan eklemek, kullanıcıların kayıtlı ilerlemesini göç riskiyle
karşı karşıya bırakır. Künye uygulamanın çalışması için gerekli değil; bize
gerekli.

---

## Parti 00 — devralınan havuz

| Alan | Değer |
|---|---|
| Tarih | 2026-08-15'ten önce |
| Soru sayısı | 680 → **679** (1 birebir tekrar eden soru silindi: Kanun-i Esasi/1876) |
| Kaynak | Devralınan `seed_questions.json` |
| Doğrulama | Madde referansları mevcut, ancak üretim kaynağı ve tarihi kayıtlı değil |
| Uygulanan dönüşüm | Şık sıraları yeniden dağıtıldı (doğru cevap A-E arasında ~%20 eşit). Soru metinleri, şık metinleri ve doğru cevaplar değişmedi; dönüşüm `tools/rebuild_pool.py` ile tekrar çalıştırılabilir ve içeriği bozmadığını kendisi doğruluyor. |
| Bilinen borç | Açıklamalar kısa (ortalama 228 karakter, hedef 450-750) · doğru cevap soruların %64'ünde en uzun şık · 155 soruda dayanak madde değil doktrin |

---

## Parti 01 — İş Hukuku + Hukuk Yargılama Usulü

| Alan | Değer |
|---|---|
| Tarih | 2026-08-15 |
| Soru sayısı | **25** (İş Hukuku 15 · Hukuk Yargılama Usulü 10) |
| Zorluk | 5 kolay · 13 orta · 7 zor |
| Açıklama uzunluğu | min 509 · ortalama 566 · maks 719 karakter |
| Doğru şık en uzun | %8 (kapı reddi sonrası düzeltildi; ilk hâli %56 idi) |

**Dayanak maddeler ve kaynaklar:**

| Ders | Maddeler | Kaynak | Kaynağın niteliği |
|---|---|---|---|
| İş Hukuku | 4857 s. İş K. m. 17, 18, 20, 24, 25 | Lexpera konsolide metin | Tam metin alındı, kanun diliyle tutarlı, bütünlük denetiminden geçti |
| Hukuk Yargılama Usulü | 6100 s. HMK m. 114, 115, 119, 127, 141 | adalet.gov.tr resmî PDF | Tam metin alındı, bütünlük denetiminden geçti |

**Bu partide YAZILMAYAN konular ve sebebi:**

| Konu | Sebep |
|---|---|
| Anayasa Hukuku (m. 13, 15, 38, 90, 148, 152) | Kaynak metni bozuk döndü. m. 13 için gelen metin "sosyal, ekonomik ve siyasi hayatın gerekleri ile kamu yararı için sınırlanabilir" idi; bu yürürlükteki hüküm değil. Aynı turda m. 15, 90, 148 ve 152 de bozuktu. Protokol 24.1 kaynak bütünlüğü denetimi uygulandı, soru yazılmadı. |
| HMK m. 176-177 (ıslah) | Kaynak PDF m. 148'de kesiliyordu, madde metnine ulaşılamadı. |
| İş K. m. 53, 63 (yıllık izin, çalışma süresi) | Kaynak sayfasında bu maddeler yer almıyordu. |

**Onay kapısı sonucu:** `Tools/soru_denetim.py` — tam standart, 0 hata.

**Kapının yakaladığı ve düzeltilen sorun:** İlk üretimde 25 sorunun 14'ünde
doğru cevap en uzun şıktı (%56; rastgelede beklenen %20). Kapı reddetti;
çeldiriciler hukuken daha anlamlı ve karşılaştırılabilir uzunlukta olacak
şekilde yeniden yazıldı. Doğru cevaplar ve dayandıkları maddeler değişmedi.
En iyi kazanım: "İşçinin haklı nedenle feshi" sorusuna, m. 25/III'ün metni
(işverenin aynı durumdaki hakkı) çeldirici olarak eklendi — hem uzunluk
dengelendi hem soru gerçekten öğretici hâle geldi.

---

## Kayıt şablonu (sonraki partiler için)

```
## Parti NN — <dersler>

| Alan | Değer |
|---|---|
| Tarih | YYYY-AA-GG |
| Soru sayısı | N |
| Zorluk | x kolay · y orta · z zor |
| Açıklama uzunluğu | min / ortalama / maks |
| Doğru şık en uzun | %N |

Dayanak maddeler ve kaynaklar: <tablo>
Bu partide yazılmayan konular ve sebebi: <tablo>
Onay kapısı sonucu: <0 hata / N hata → düzeltildi>
```

---

## Parti A-01 — Medeni Hukuk (açıklama zenginleştirme)

| Alan | Değer |
|---|---|
| Tarih | 2026-08-16 |
| İşlem | Mevcut soruların `explanation` alanı yenilendi; soru metni, şıklar ve doğru cevap değişmedi |
| Açıklama sayısı | 27 |
| Açıklama uzunluğu | 688 / 719 / 749 karakter |
| Katman | kural → neden doğru → çeldirici çürütme → ayrım ipucu (dördü de zorunlu) |

**Kaynak:** `Kanunlar/4721-turk-medeni-kanunu.txt` — 4721 sayılı Türk Medenî
Kanunu, Mevzuat Bilgi Sistemi metni; oturumda `.doc` ikili biçimden UTF-8 düz
metne dönüştürüldü (16.08.2026). Metin, Anayasa m.13 benzeri "yürürlükten kalkmış
hâli döndürme" hatasına karşı örneklem üzerinden sınandı: m.187'nin iptal şerhi
metinde doğru biçimde görünüyor.

**Dayanak maddeler (27 sorunun her biri metinden okunarak doğrulandı):**
TMK m. 2 · 3 · 12 · 15 · 27 · 28 · 32-33 · 56 · 102 · 118-119 · 124 · 166 · 194 ·
202 · 289 · 306 · 336 · 364 · 397 · 413 · 506 · 510 · 538 · 606 · 683 · 705 ·
713 · 973.
Çeldirici çürütmelerinde ayrıca metinden okunarak kullanılanlar: m. 11 · 16 ·
120 · 145 · 161 · 164 · 175 · 605 · 712 · 763.

**Doğrulanamadığı için yazılmayan konu:** yok — bu partideki her madde
`Kanunlar/` klasöründeki resmî metinden okunarak doğrulandı.

**Havuza yazılmayan, onay bekleyen üç soru:**

| id | Sorun | Öneri |
|---|---|---|
| 5e65ce3b | TMK m.187'nin ilgili cümleleri AYM'nin 22/2/2023 tarihli E.2022/155, K.2023/38 sayılı kararıyla iptal edildi; soru yürürlükte olmayan kuralı öğretiyor | ÇIKARILMALI |
| 21bcee37 | Doğru şık "kişilik"i "hak ehliyeti" ile karıştırıyor; m.28/1 kişiliğin geriye etkisini öngörmüyor | Şık düzeltilmeli |
| e9242367 | c4923069 ve 8a985bf9 ile aynı kuralı ölçüyor (m.15 tekrarı); ayrıca "askıda geçersiz (iptal edilebilir)" şıkkı iki ayrı kavramı birleştiriyor | ÇIKARILMALI |

**Ayrıca düzeltilmesi önerilen alan:** fbea2b5a — `lawReference` "TMK m. 396,
397, 408" olarak kayıtlı; m.408 kısıtlama sebeplerine ilişkin olup soruyla
ilgisiz, atamayı düzenleyen m.413 ise eksik. Önerilen: "TMK m. 397, 413".

**Altyapı düzeltmesi (bu oturum):** `Kanunlar/` klasöründeki 40 kanun eski Word
(.doc) ikili biçimindeydi ve `havuz.py kaynak-dogrula` hiçbirini okuyamıyordu
(704 sorunun 574'ü "doğrulanamadı"). Dosyalar UTF-8 düz metne çevrildi, `.doc`
asılları `Kanunlar/_doc_arsiv/` klasörüne alındı. Yeni durum: **doğrulandı 583 ·
elle 130 · doğrulanamadı 8**.

**Kalan 8 doğrulanamayan referans:**
- Kanun metni klasörde yok: 1475 s. İş K. m.14 · 193 s. GVK m.1-2 · 5520 s. KVK
  m.1 · 5070 s.K. m.5 · 7887 s. CB Kararı (5 soru)
- Aracın referans ayrıştırıcısının yanılması: "AY m.148; 6216 s.K. m.47" biçimindeki
  üç kayıtta ilk madde numarası Anayasa'ya ait olduğu hâlde 6216'da aranıyor (3 soru)

**Onay kapısı sonucu:** `havuz.py aciklama` — 27 açıklama yazıldı, çıkış kodu 0,
yedek `seed_questions_20260816-193757_aciklama.json`.

---

## Parti A-02 … A-07 — Açıklama zenginleştirme (16.08.2026)

Hepsinde aynı yöntem: soru metni, şıklar ve doğru cevap değişmedi; yalnızca
`explanation` dört katmanlı standarda (kural → neden doğru → çeldirici çürütme →
ayrım ipucu) yeniden yazıldı. Her madde `Kanunlar/` klasöründeki resmî düz metin
sürümünden okunarak doğrulandı. Uzunluklar 617-749 karakter aralığında.

| Parti | Ders | Adet | Kaynak dosya |
|---|---|---|---|
| A-02 | Borçlar Hukuku | 26 | 6098-turk-borclar-kanunu.txt |
| A-03 | Ticaret Hukuku | 23 | 6102-turk-ticaret-kanunu.txt |
| A-04 | Hukuk Yargılama Usulü | 23 | 6100-hukuk-muhakemeleri-kanunu.txt |
| A-05 | Ceza Hukuku | 23 | 5237-turk-ceza-kanunu.txt (+ 5271 CMK m.223) |
| A-06 | Medeni Hukuk (2. tur) | 21 | 4721-turk-medeni-kanunu.txt |
| A-07 | İş ve Sosyal Güvenlik | 20 | 4857-is-kanunu.txt, 5510, 6098 (TBK m.420) |

**Dayanak maddeler**
- A-02 — TBK m. 1, 19, 21, 27, 28, 39, 49, 82, 89, 117, 120, 139, 143, 146, 147,
  163, 180, 184, 196, 219, 288, 342, 470, 506, 583, 620 (çürütmelerde ayrıca
  m. 4, 12, 30, 36, 37, 72, 182, 207, 237, 299, 393, 502).
- A-03 — TTK m. 4, 7, 11, 15, 18, 19, 36, 37, 39, 54, 56, 64, 89, 102, 124, 329,
  338, 397, 413, 573, 574, 671, 677, 698, 776, 777, 780, 795, 796.
- A-04 — HMK m. 2, 4, 6, 12, 25, 33, 84, 108, 114, 115, 118, 169, 176, 190, 248,
  266, 303, 307, 308, 311, 317, 326, 341, 345, 389, 400.
- A-05 — TCK m. 21, 22, 25, 29, 30, 31, 32, 35, 36, 38, 39, 43, 44, 51, 66, 73,
  81, 82, 141, 157, 257; CMK m. 223.
- A-06 — TMK m. 16, 17, 18, 19, 26, 27, 72, 73, 80, 132, 145, 151, 295, 501, 502,
  545, 571, 688, 712, 713, 747, 797, 1007.
- A-07 — İş K. m. 11, 15, 17, 18, 21, 22, 24, 25, 26, 41, 53, 63, 68, 69;
  5510 s.K. m. 4, 13; TBK m. 420.

**Doğrulanamadığı için yazılmayan konu:** 1475 sayılı (mülga) İş Kanunu m.14 —
kıdem tazminatının yürürlükteki dayanağı. Kanun metni `Kanunlar/` klasöründe yok;
bu maddeye dayanan iki soru (033e756f, a9b5db58) bu turda ellenmedi.

**Onay kapısı:** altı partinin altısı da `havuz.py aciklama` ile uygulandı,
çıkış kodu 0, her birinde yedek alındı.

**Havuzun durumu:** açıklama borcu %90.8 → **%67.6**; ortalama açıklama uzunluğu
250 → 362 karakter. Bu oturumda toplam 136 açıklama yenilendi.

---

## ONAY BEKLEYEN SORULAR (16.08.2026 itibarıyla, havuza dokunulmadı)

### Yürürlükte olmayan hukuku öğreten sorular — acil
| id | Ders | Sorun |
|---|---|---|
| 5e65ce3b | Medeni | TMK m.187, AYM'nin 22/2/2023 tarihli E.2022/155, K.2023/38 kararıyla iptal edildi |
| 972bed74 | HMK | Belirsiz alacak davası (HMK m.107) 16/7/2026 tarihli 7589 s.K. m.19 ile **mülga**; kurum HMK metninden çıkarıldı |
| 58673be3 | İş | Analık izni: İş K. m.74 "doğumdan önce 8, sonra **16** hafta, toplam **24** hafta" diyor. Soruda işaretli cevap 8+8=16 hafta (eski hüküm) ve hiçbir şık doğru değil |

### Doğru cevabı yanlış olan soru
| id | Ders | Sorun |
|---|---|---|
| 7c388d13 | Borçlar | Soru "hazır olmayanlar arasında öneri" diyor, işaretli cevap TBK **m.4**'ün (hazır olanlar) kuralı. m.5 farklı bir ölçüt getiriyor |

### Tekrar eden sorular (aynı kuralı ikinci kez ölçüyor)
| id | Ders | Eşi |
|---|---|---|
| e9242367 | Medeni | 8a985bf9 (TMK m.15) |
| 9fa3a68b | Borçlar | 320411af (TBK m.72) |
| 1d07106a | Borçlar | 8681220a (TBK m.82) |
| 27f4be61 | Borçlar | 033a8216 (TBK m.49) — ayrıca soru kökü bozuk |
| 71431ba0 | Ticaret | 766c6757 (kambiyo senetleri) |
| 9bdf7a23 | Ticaret | 35a917f5 (basiretli iş adamı) — ayrıca lawReference m.20 yanlış, doğrusu m.18/2 |
| 365720dd | HMK | 2dff6001 (HMK m.25) |
| c8963196 | HMK | 2707476a (HMK m.176) |
| d36c1480 | Ceza | 99b5c220 (TCK m.35) |
| 9ef6a01f | Ceza | b7d6ee73 (TCK m.25) |
| 033e756f | İş | a9b5db58 (kıdem tazminatı 1 yıl) |
| 9ee3c363 | İş | 15672fd0 (işe iade eşikleri) |

### Şıkkı veya kurgusu düzeltilmeli
| id | Ders | Sorun |
|---|---|---|
| 21bcee37 | Medeni | Doğru şık "kişilik"i "hak ehliyeti" ile karıştırıyor (TMK m.28/1'de geriye etki yok) |
| acc0427f | Medeni | Vakıf amacı: TMK m.113 (amacın değiştirilmesi) ile m.116 (kendiliğinden sona erme) arasında kalıyor; iki şık da savunulabilir |
| ef6c5001 | Medeni | "Dava açmadan icra takibi başlatamaz" şıkkı genel hukuka aykırı (ilamsız takip mümkün) |
| f48030b7 | Ceza | Kuralı değil madde numarasını ölçüyor |
| cc8e36ec | Ticaret | AŞ asgari sermayesi (250.000 TL) 7887 s. CB Kararı'na dayanıyor; metin `Kanunlar/` klasöründe yok, doğrulanamadı |
| fbea2b5a | Medeni | lawReference "TMK m. 396, 397, 408" — m.408 ilgisiz, atamayı düzenleyen m.413 eksik |
| 84604116 | Ticaret | lawReference "TTK m. 731" yanlış; kabulün hükmü **m.698**'de. Açıklama m.698'e göre yazıldı |

### Havuz geneli — yapısal
Doğru cevabın tek başına en uzun şık olduğu soru sayısı 379/704; ikinci en uzun
şıktan %25'ten fazla uzun olanlar 305 (%43). Şıkların uzunluk dengesi ayrı bir
onay gerektiriyor (şık metni değişeceği için).

---

## Parti 08 — ONARIM PARTİSİ (16.08.2026)

Kullanıcı onayıyla, iskeleti sağlam ama hükmü eskimiş/yanlış soruları çıkarmak
yerine güncel kanuna göre yeniden kurma yetkisi verildi. Araçta alan düzenleme
komutu bulunmadığından yöntem: eski kayıt `cikar`, onarılmış kayıt yeni `id` ile
`ekle`. Havuz 704 → 682 → **691**.

**Çıkarılan 22 soru:** 9 onarılan aslı + 12 tekrar + 1 onarılamayan
(5e65ce3b, TMK m.187 iptal edildiği için yerine koyulacak yürürlükte kural yok).

**Onarılan 9 soru:**

| Eski id | Sorun | Onarım |
|---|---|---|
| 58673be3 | Analık izni 8+8=16 hafta (eski hüküm); hiçbir şık doğru değildi | Şıklar 8+16=24 haftaya göre yeniden kuruldu |
| 7c388d13 | Doğru cevap TBK m.4'ün kuralıydı, soru m.5'i soruyordu | m.5'e uygun şık seti; m.4 kuralı çeldirici yapıldı |
| 21bcee37 | Doğru şık kişiliği hak ehliyetiyle karıştırıyordu | Şık m.28/1'e indirgendi; doğru şık artık en kısa şık |
| acc0427f | m.113 ile m.116 arasında kalıyordu, iki şık savunulabilirdi | Soru kökü m.113'e sabitlendi |
| ef6c5001 | "Dava açmadan icra takibi yapamaz" şıkkı genel hukuka aykırıydı | m.25'te sayılmayan gerçek bir talep çeldirici yapıldı |
| 972bed74 | Belirsiz alacak davası (HMK m.107) 16/7/2026'da mülga | Kısmi davaya (HMK m.109, 2026 eki dâhil) dönüştürüldü |
| f48030b7 | Kuralı değil madde numarasını ölçüyordu | TCK m.2'nin içeriğini ölçen soruya çevrildi |
| fbea2b5a | lawReference "m. 396, 397, 408" hatalıydı | "TMK m. 397, 413"; şıklara denetim makamı eklendi |
| 84604116 | lawReference "TTK m. 731" hatalıydı | "TTK m. 698" |

Dokuz sorunun hiçbirinde doğru cevap tek başına en uzun şık değil.
**Onay kapısı:** `denetle` ilk turda soru metni tekrarını yakaladı (eski kayıt
henüz çıkarılmamıştı); sıra düzeltildikten sonra yeni parti ve birleşik havuz
"hata yok" verdi.

**Web ile teyit edilenler (kırmızı bayrak kuralı):**
- İş K. m.74 — 7578 s.K., yürürlük 1.5.2026: analık izni 8+16=24 hafta, doktor
  onayıyla doğum öncesi çalışma 3 → 2 haftaya indi. İki bağımsız kaynakla teyit.
- TTK m.332 — 7887 s. CB Kararı (RG 25.11.2023), 1.1.2024'ten itibaren AŞ
  250.000 TL, kayıtlı sermayede başlangıç 500.000 TL. Soru doğru çıktı, onarım
  gerekmedi.

---

## Parti 09 … 12 — Açıklama zenginleştirme (16.08.2026)

| Parti | Ders | Adet |
|---|---|---|
| A-09 | Borçlar Hukuku (2. tur) | 26 |
| A-10 | Ticaret Hukuku (2. tur) | 24 |
| A-11 | İcra ve İflas Hukuku | 20 |
| A-12 | Anayasa Hukuku | 21 |

**Yeni kural — güncellik damgası:** Parti 09'dan itibaren her açıklama
`[Dayanak metin: <kanun no> s.K., <tarih> tarihli sürüm]` satırıyla bitiyor.
Amaç, hüküm ileride değişirse kullanıcının açıklamanın hangi tarihli metne
dayandığını görüp kendisi teyit edebilmesi. Şema sabit tutuldu; `verifiedAt`
gibi yeni bir alan EKLENMEDİ (uygulama kodunda çözücü değişikliği gerektirir).
Parti 01-08 arasındaki 163 açıklamaya damga sonradan toplu geçişle eklenecek.

**Kanun dosyalarının güncellik durumu** (metindeki en son değişiklik tarihinden):
HMK 31.10.2026 · TCK/CMK/TBK/İİK/İYUK 31.07.2026 · İş K. 01.05.2026 ·
TTK 31.12.2026 · TMK 25.12.2025 · Anayasa 03.11.2019. Korpus güncel.

**Bu turda bulunan ve çıkarılan tekrarlar:** İİK m.62 üç kez (25cd4904,
824b5ac9 çıkarıldı), İİK m.83 iki kez, İİK m.43 iki kez, AY m.83 iki kez,
AY m.75/77 üçlü örtüşme — bu turda partiye alınmadılar, sonraki onarım
partisinde ele alınacak.

**Doğrulanamayan:** 1475 s. (mülga) İş K. m.14 — hâlâ klasörde yok.

**Havuzun durumu:** 691 soru · açıklama borcu %90.8 → **%52.8** ·
ortalama açıklama 250 → **430 karakter**. Bu oturumda toplam **254 açıklama**
yenilendi, 9 soru onarıldı, 22 soru çıkarıldı.

---

## Parti 13 … 17 — Açıklama zenginleştirme + onarım turu (17.08.2026)

**Oturum özeti:** 76 açıklama dört katmanlı standarda çıkarıldı · 20 soru
çıkarıldı (17'si tekrar, 3'ü yürürlükteki metinle çelişki) · 20 soru yeniden
kuruldu ve havuza eklendi. Havuz 691 → 691 (sayı sabit, içerik yenilendi).
Açıklama borcu **%52,8 → %37,5**; ortalama açıklama **430 → 500 karakter**.

| Parti | Ders | Açıklama | Çıkarılan | Eklenen |
|---|---|---|---|---|
| A-13 | Ceza Yargılama Usulü | 21 | 3 | 2 |
| A-14 | İdare Hukuku | 22 | – | – |
| A-15 | Hukuk Yargılama Usulü | 22 | – | – |
| A-16 | İdari Yargılama Usulü | 10 | 9 | 8 |
| A-17 | Milletlerarası Özel Hukuk | 11 | 8 | 10 |

### Dayanak maddeler (hepsi `Kanunlar/` klasöründeki resmî düz metinden, 17.08.2026'da okundu)

- **CMK (5271):** m. 2, 40, 41, 50, 90, 91, 100, 101, 109, 118, 119, 147, 148,
  150, 164, 170, 173, 174, 182, 185, 206, 217, 237
- **Anayasa (2709):** m. 2, 38, 46, 123, 124, 125, 127, 128, 129
- **657 s. DMK:** m. 48, 125 · **TMK (4721):** m. 715, 999
- **İYUK (2577):** m. 2, 7, 10, 11, 14, 15, 16, 27, 28, 45, 46 ·
  **2576 s.K.:** m. 5, 6
- **HMK (6100):** m. 17, 27, 30, 31, 50, 51, 65, 66, 94, 102, 105, 106, 107,
  110, 119, 123, 127, 132, 165, 166, 188, 225, 227 · **TTK (6102):** m. 5/A
- **MÖHUK (5718):** m. 1, 4, 5, 7, 9, 12, 13, 14, 15, 20, 21, 24, 27, 34, 40,
  41, 47, 50, 54, 58

### Yürürlükteki metinle çelişen ve onarılan üç soru

| Eski id | Sorun | Onarım |
|---|---|---|
| 99876788 | Eski hâle getirme süresi "yedi gün" işaretliydi; CMK m.41 **iki hafta** diyor. Hiçbir şık doğru değildi. | Süre + merci birlikte sorulacak şekilde yeniden kuruldu; "yedi gün" en güçlü çeldirici yapıldı. |
| abf4edb9 | KYOK itirazı "15 gün" işaretliydi; CMK m.173 **iki hafta**. | Şıklar iki haftaya göre kuruldu; sulh ceza hâkimliği mercii korundu. |
| 9962b21d | Teminat kuralı ters kurulmuştu; "sermayesinin %51'i kamuya ait kuruluşlar" ibaresi İYUK m.27'de **yok**. Hiçbir şık doğru değildi. | m.27/6'nın üç cümlesine göre yeniden kuruldu (kural + iki istisna). |
| 5ae0225e | Vatansızlarda "mutad mesken, o da yoksa Türk hukuku" işaretliydi; MÖHUK m.4/1-a **yerleşim yeri → mutad mesken → dava tarihinde bulunulan ülke** diyor. | Üç basamaklı doğru sıralama ile yeniden kuruldu. |
| 43fab38a | Hukuk seçimi yoksa "en sıkı ilişkili hukuk (kural olarak **edimin ifa yeri**)" deniyordu; MÖHUK m.24/4 ölçütü **karakteristik edim borçlusunun mutad meskeni/işyeri**. | Parantez içi hatalı ölçüt çıkarıldı, doğru somutlaştırma ile yeniden kuruldu. |
| 8357d511 | İçerik doğruydu ama `topicTag` "Zorunlu İdari Başvuru" idi; İYUK m.11 başvurusu **ihtiyaridir**. | "Üst Makama Başvuru ve Sürenin Durması" olarak yeniden kuruldu. |

### Çıkarılan tekrarlar (aynı kuralı ikinci kez ölçüyordu)

- **CMK:** `3071fab5` — gözaltı 24 saat, `cba95810` ile birebir aynı kural.
- **İYUK — yürütmenin durdurulması iki şartı dört kez soruluyordu:**
  `099eb05a`, `6f59bc0c`, `94c609ac` çıkarıldı; `779b2194` bırakıldı.
- **İYUK — 60 günlük genel dava açma süresi üç kez:** `b8d95550`, `01a53265`
  çıkarıldı; `a3828141` bırakıldı.
- **İYUK — genel görevli mahkeme iki kez:** `1bb124ac` çıkarıldı (dayanağı
  "2575; 2576; 2577" biçiminde belirsizdi); `e013efb5` (2576 m.5) bırakıldı.
- **İYUK — dava türleri iki kez:** `a0c2a09c` çıkarıldı; şıklarından biri
  ("kamu ihale sözleşmelerinden doğan bazı davalar") idari sözleşme–özel hukuk
  sözleşmesi ayrımını bulanıklaştırıyordu. `34582bac` bırakıldı.
- **MÖHUK — ehliyet/millî hukuk üç kez:** `3632a658`, `04bd83ff` çıkarıldı;
  `b51558a4` bırakıldı.
- **MÖHUK — m.1 kapsamı iki kez:** `85612479` çıkarıldı; `32db6bd8` bırakıldı.
- **MÖHUK — hukuk seçimi (m.24/1) iki kez:** `d1923846` çıkarıldı; `9436fe9c`
  bırakıldı.
- **MÖHUK — kamu düzeni (m.5) iki kez:** `d107ae57` çıkarıldı; `2ac55215`
  bırakıldı.
- **MÖHUK — tenfiz şartları iki kez:** `6b041263` çıkarıldı; dört şartı birden
  ölçen `1dc3c147` bırakıldı.

### Havuza eklenen yeni sorular

- **CMK (2):** eski hâle getirme (m.40-41), KYOK itirazı (m.173).
- **İYUK (8):** üst makama başvuru ve sürenin durması (m.11), teminat (m.27/6),
  idari makamlara başvuru ve zımni ret (m.10), ilk inceleme konuları (m.14/3),
  YD kararına itiraz (m.27/7), kararların uygulanması (m.28), Danıştayda temyiz
  (m.46), ilk inceleme üzerine verilecek karar (m.15).
- **MÖHUK (10):** hukuk seçimi yokluğu (m.24/4), vatansızlar (m.4), işlem şekli
  (m.7), nişanlanma (m.12), evliliğin şekli (m.13/2), evlilik malları (m.15),
  haksız fiil (m.34), Türklerin kişi hâlleri (m.41), yabancı mahkeme yetki
  anlaşması (m.47), tanıma–tenfiz farkı (m.58).

### Web ile teyit edilen (kırmızı bayrak kuralı — yalnızca bir konu)

- **CMK m.41 / m.173 "iki hafta"**: yerel resmî metin, sürelerin gün yerine
  hafta cinsinden yazıldığı 2024 düzenlemesini tutarlı biçimde gösteriyordu
  (m.41, 173, 268, 273, 277 hepsi "iki hafta"). Eski Yargıtay kararlarında
  "yedi gün" geçtiği için ikinci kaynaktan teyit edildi; yürürlükteki metin
  **iki hafta**. Diğer maddelerde kırmızı bayrak görülmediğinden web
  kullanılmadı.

### Yerel metinde saptanan yürürlük notları (ileride sorulara etki eder)

- **HMK m.107 (belirsiz alacak davası) 16.07.2026'da mülga** (7589 s.K.).
  Bu turda yalnızca çeldirici olarak geçiyor; açıklamada mülga olduğu
  belirtildi. Havuzda belirsiz alacak davasını **doğru cevap** yapan bir soru
  kalmadığı doğrulandı.
- **HMK m.166/1**, 16.07.2026-7589/23 ile değişti (birleştirme kararının
  kesinleşmesi).
- **MÖHUK m.27/1**, 04.06.2025-7550/18 ile değişti; açıklama yeni metne göre
  yazıldı.
- **İYUK m.45** parasal sınırı 28.07.2024-7524 ile 31.000 TL, **m.46/1-b**
  920.000 TL. Bu rakamlar sorulara alınmadı; parasal sınırlar sık değiştiği
  için soru yazmaya elverişli değil.

### Doğrulanamadığı için yazılmayan konular

- **1475 s. (mülga) İş K. m.14** — hâlâ `Kanunlar/` klasöründe yok (önceki
  turdan devreden borç).
- Bu turda ele alınan beş dersin bütün maddeleri yerel resmî metinden
  doğrulandı; doğrulanamadığı için atlanan başka konu **yok**.

### Onay kapısı çıktıları

- `aciklama_13/14/15/16/17.json` → beşi de "hata yok", alan değişikliği yok.
- `parti_13.json` (2 soru) → "hata yok".
- `parti_16.json` (8 soru) → ilk turda "doğru şık en uzun olan %62,5" hatası;
  **eşik düşürülmedi, çeldiriciler güçlendirildi**, ikinci turda "hata yok".
- `parti_17.json` (10 soru) → ilk turda %70 hatası; aynı yolla düzeltildi,
  ikinci turda doğru şıkkın en uzun olduğu soru sayısı **0/10**.
- Birleşik havuz her işlemde "hata yok".

### Araç notu

`Yedekler/` klasöründe yedek döndürme sırasında silme izni alınamadı
(`PermissionError`). Eski yedekler silinmeyip `Yedekler/_arsiv/` altına
taşındı; havuz bu sırada değişmedi, işlem yeniden çalıştırıldı ve başarılı
oldu. Yedek zinciri eksiksiz.

### Havuzun durumu

691 soru · açıklama borcu **%37,5** (259 soru) · ortalama açıklama
**500 karakter** · doğru şık dağılımı A %20,0 · B %21,0 · C %19,8 · D %20,1 ·
E %19,1. En çok borcu kalan dersler: Avukatlık Hukuku 19 · Anayasa Yargısı 19 ·
Vergi Usul Hukuku 19 · Genel Kamu Hukuku 19 · Milletlerarası Hukuk 18.

**Xcode'da ⌘U çalıştır.**
