# HMGS Koçu — Proje Belgesi

> Bu dosya projeye yeni bakan birinin (ya da yeni bir sohbetin) "burada ne var,
> ne hedefleniyor, nasıl çalışılıyor" sorularına 5 dakikada cevap vermesi için var.

## 1. Fikir sözleşmesi (5 madde)

1. **Kime:** HMGS'ye hazırlanan hukuk mezunlarına.
2. **Ne zaman:** Boşta kalan 10-15 dakikalarda (yolda, sıra beklerken) ve akşam
   ders çalışırken, telefonla, çoğunlukla tek elle.
3. **Hangi işi bitiriyor:** Soru çözdürüyor, yanlışları otomatik biriktirip tekrar
   karşına çıkarıyor ve HMGS temposunda (120 soru / 155 dakika) deneme yaptırıyor.
4. **Ayrışma noktası:** HMGS'ye özel; sorular resmî ders dağılımına (Medeni 15/120,
   Ceza 9/120 …) göre çekiliyor, her sorunun dayandığı kanun maddesi yazılı ve
   yanlışlar "hata havuzu" olarak kalıcı takip ediliyor. Genel bir "quiz" uygulaması
   değil, tek bir sınavın müfredatına oturtulmuş bir çalışma aracı.
5. **Kesinlikle olmayacaklar (v1 sınırı):** Hesap/kayıt yok, sunucu yok, reklam yok,
   sosyal özellik yok, kullanıcı içeriği (UGC) yok, ücretli özellik yok.

## 2. Profil

| Alan | Değer |
|---|---|
| Uygulama adı | HMGS Koçu |
| Tek cümlelik vaat | HMGS'ye hazırlanan hukuk mezununa, boştaki 10 dakikasında, gerçek sınav dağılımıyla soru çözdürüp yanlışlarını takip eder |
| Platform | iOS (iPhone) |
| Minimum iOS | 17.0 |
| Ülke / dil | Türkiye / Türkçe |
| Hedef kitle | 22-35, hukuk mezunu, teknik uzmanlığı olmayan yetişkin |
| Kullanım anı | Çoğunlukla ayakta/yolda, tek elle, kısa oturumlar; akşam uzun deneme |
| Gelir modeli | v1 ücretsiz; ücretlendirme altyapısı hazır ama kapalı (bkz. `Services/Entitlements.swift`) |
| Backend | Yok. Her şey cihazda. |
| Toplanan veri | **Hiç.** Sunucu yok, hesap yok, izleme yok. |
| Üçüncü taraf SDK | **Yok.** Sıfır bağımlılık. |
| Yapay zekâ | Uygulama içinde kullanılmıyor |
| Yayın hesabı | Apple Developer Team `57YXLH9LTN` |

## 3. Mimari

```
HMGSKocuApp.swift        Açılış akışı (splash → karşılama → tur → uygulama)
Models/                  Saf veri tipleri, iş kuralları taşıyan yapılar
  Question.swift           Soru + LegalSubject (24 ders, 20'si resmî) + HMGS ağırlıkları
  ExamSession.swift        Oturum, kapsam, yapılandırma, ExamLaunch, InProgressExam
  UserProgress.swift       QuestionStat, SubjectProgress, Achievement kataloğu
  Stage.swift              Yolculuk aşama sistemi + JourneyCatalogue.reconcile
  LawQuote.swift           Açılış ekranı özdeyişleri
  AppSettings.swift        UserDefaults anahtarları, AppInfo, ContentPolicy
Services/                Yan etkili işler; hepsi protokolsüz ama tek sorumluluklu
  LocalStore.swift         Diske JSON yazma/okuma, atomik + dosya koruması
  AppDataStore.swift       ViewModel'ların konuştuğu TEK servis + PersistenceActor
  SeedQuestionLoader.swift Bozuk içeriğe dayanıklı soru çözümleyici
  QuestionSelector.swift   Öncelik sırası + ağırlıklı tam deneme
  ScoringEngine.swift      HMGS puanlaması + AchievementEngine
  XPEngine.swift           Yolculuk XP/seviye kuralları
  TimerEngine.swift        Arka plana dayanıklı, monotonik sınav saati
  Entitlements.swift       Ücretlendirme kancası (v1'de her şey açık)
  Feedback.swift           Haptik + soru hatası bildirme (mailto)
  AppLog.swift             Kişisel veri içermeyen teknik günlük
ViewModels/              Her ekranın durumu; SADECE AppDataStore ile konuşur
Views/                   Görünüm ve etkileşim; iş mantığı yok
  Theme.swift              Tasarım jetonları, buton stilleri, Format yardımcıları
Resources/               seed_questions.json, Assets.xcassets, PrivacyInfo.xcprivacy
HMGSKocuTests/           XCTest paketi (motorlar + göç + gerçek içerik denetimi)
```

**Katman kuralı:** View → ViewModel → AppDataStore → PersistenceActor → LocalStore.
Bir View'ın `LocalStore`'u doğrudan çağırdığını görürsen bu bir hatadır.

## 4. Yolculuk modu (oyunlaştırma)

- Aşamalar **türetilir**, elle yazılmaz: her dersin soru havuzu 8'erli dilimlere
  bölünür, zorluk artan sırada.
- `JourneyCatalogue.reconcile` sözleşmesi: **eski aşamalar asla değişmez.** Yeni
  soru geldiğinde önce son yarım aşama doldurulur, sonra sona yeni aşama eklenir.
  Havuzdan kaldırılan sorular aşamadan düşer ama aşama indeksleri kaymaz.
  Bu kural bozulursa kullanıcının "5. aşamayı geçtim" kaydı sessizce başka bir
  soru kümesini işaret etmeye başlar. `HMGSKocuTests/JourneyAndSelectionTests` bunu
  altı ayrı testle koruyor.
- Doğru başına 10 XP; aşamayı ilk geçişte +20, tekrar geçişte +5. Geçme eşiği %70.
- Maskot **Kukuk** — kodla çizilmiş, telifsiz.

## 5. Sürüm geçmişi

- **1.0.0 (bu sürüm)** — App Store'a hazır ilk yapı.
