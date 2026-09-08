// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import Foundation

/// Bir sorunun bu kullanıcıdaki tüm denemeler boyunca birikmiş sayaçları —
/// "bu soruyu 3 kez yanlış yaptım" takibini ve hata havuzunu besleyen kayıt.
struct QuestionStat: Codable, Identifiable, Hashable, Sendable {
    var id: UUID { questionID }
    let questionID: UUID
    var subject: LegalSubject
    var attempts: Int
    var correct: Int
    var wrong: Int
    /// Sınav erken bitirildiğinde cevapsız kalma sayısı. `wrong`'dan ayrı tutuluyor:
    /// boş bırakmak yanlış yapmak değildir, doğruluk oranını düşürmemeli — ama soru
    /// yine de tekrar karşına çıkmalı.
    var blank: Int
    var lastAttemptDate: Date
    var isInMistakePool: Bool   // doğru cevaplandığı anda tekrar false olur
    /// Son denemenin boş mu yanlış mı olduğu — havuzda "Yanlış" mı "Boş" mu
    /// bölümünde görüneceğini belirler.
    var wasLastAttemptBlank: Bool
    /// Soru hata havuzundayken doğru cevaplandığında artan sayaç ("Kazanılan Sorular").
    var reclaimedCount: Int

    var wrongRate: Double { attempts == 0 ? 0 : Double(wrong) / Double(attempts) }

    init(
        questionID: UUID,
        subject: LegalSubject,
        attempts: Int,
        correct: Int,
        wrong: Int,
        blank: Int = 0,
        lastAttemptDate: Date,
        isInMistakePool: Bool,
        wasLastAttemptBlank: Bool = false,
        reclaimedCount: Int = 0
    ) {
        self.questionID = questionID
        self.subject = subject
        self.attempts = attempts
        self.correct = correct
        self.wrong = wrong
        self.blank = blank
        self.lastAttemptDate = lastAttemptDate
        self.isInMistakePool = isInMistakePool
        self.wasLastAttemptBlank = wasLastAttemptBlank
        self.reclaimedCount = reclaimedCount
    }

    // Eski sürümlerde kaydedilmiş JSON (yeni alanlar olmadan) hâlâ okunabilsin diye
    // elle yazılmış çözümleme. Bu bir GÖÇ (migration) yolu — yeni alan eklerken
    // mutlaka `decodeIfPresent` + varsayılan kullan, yoksa güncelleme sonrası
    // kullanıcıların tüm ilerlemesi okunamaz hale gelir.
    enum CodingKeys: String, CodingKey {
        case questionID, subject, attempts, correct, wrong, blank
        case lastAttemptDate, isInMistakePool, wasLastAttemptBlank, reclaimedCount
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        questionID = try c.decode(UUID.self, forKey: .questionID)
        subject = try c.decode(LegalSubject.self, forKey: .subject)
        attempts = try c.decodeIfPresent(Int.self, forKey: .attempts) ?? 0
        correct = try c.decodeIfPresent(Int.self, forKey: .correct) ?? 0
        wrong = try c.decodeIfPresent(Int.self, forKey: .wrong) ?? 0
        blank = try c.decodeIfPresent(Int.self, forKey: .blank) ?? 0
        lastAttemptDate = try c.decodeIfPresent(Date.self, forKey: .lastAttemptDate) ?? Date()
        isInMistakePool = try c.decodeIfPresent(Bool.self, forKey: .isInMistakePool) ?? false
        wasLastAttemptBlank = try c.decodeIfPresent(Bool.self, forKey: .wasLastAttemptBlank) ?? false
        reclaimedCount = try c.decodeIfPresent(Int.self, forKey: .reclaimedCount) ?? 0
    }
}

/// Hata Havuzu ve Profil ekranlarında gösterilen, ders bazında toplanmış sayılar.
struct SubjectProgress: Identifiable, Hashable, Sendable {
    var id: LegalSubject { subject }
    let subject: LegalSubject
    var solved: Int
    var correct: Int
    var wrong: Int

    var accuracy: Double { solved == 0 ? 0 : Double(correct) / Double(solved) }
}

/// Adı olan bir başarım. Metinler olgusal ve hukuk temalı; abartılı oyun jargonu yok.
struct Achievement: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let detail: String
    let subject: LegalSubject?   // nil == genel başarım
    var unlockedAt: Date?

    var isUnlocked: Bool { unlockedAt != nil }

    /// Kayıtta yalnızca `id` ve `unlockedAt` anlamlı — başlık/açıklama metni
    /// uygulamayla birlikte güncellenebilsin diye katalogdan okunuyor.
    enum CodingKeys: String, CodingKey { case id, title, detail, subject, unlockedAt }

    init(id: String, title: String, detail: String, subject: LegalSubject?, unlockedAt: Date?) {
        self.id = id
        self.title = title
        self.detail = detail
        self.subject = subject
        self.unlockedAt = unlockedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let decodedID = try c.decode(String.self, forKey: .id)
        let storedTitle = try c.decodeIfPresent(String.self, forKey: .title)
        let storedDetail = try c.decodeIfPresent(String.self, forKey: .detail)
        let storedSubject = try c.decodeIfPresent(LegalSubject.self, forKey: .subject)
        let template = AchievementCatalogue.all.first { $0.id == decodedID }

        id = decodedID
        title = template?.title ?? storedTitle ?? decodedID
        detail = template?.detail ?? storedDetail ?? ""
        subject = template?.subject ?? storedSubject
        unlockedAt = try c.decodeIfPresent(Date.self, forKey: .unlockedAt)
    }
}

/// Her bitmiş sınavdan sonra `AchievementEngine` tarafından değerlendirilen sabit katalog.
enum AchievementCatalogue {
    static let all: [Achievement] = [
        Achievement(id: "ilk_sinav", title: "İlk Adım",
                    detail: "İlk denemeni tamamladın.", subject: nil, unlockedAt: nil),
        Achievement(id: "baraj_gecti", title: "Barajı Geçtin",
                    detail: "Bir tam HMGS denemesinde 100 üzerinden 70'i geçtin.", subject: nil, unlockedAt: nil),
        Achievement(id: "medeni_hukuk_ustasi", title: "Medeni Hukuk'ta Netlik",
                    detail: "Medeni Hukuk'ta en az 20 soruda %90 üzeri doğruluk yakaladın.", subject: .medeniHukuk, unlockedAt: nil),
        Achievement(id: "havuz_temiz", title: "Havuzu Boşalttın",
                    detail: "Hata havuzuna düşen tüm soruları tekrar çözüp doğru yaptın.", subject: nil, unlockedAt: nil),
        Achievement(id: "yuz_soru", title: "Yüz Soru Yolda",
                    detail: "Toplamda 100 soru çözdün.", subject: nil, unlockedAt: nil),
        Achievement(id: "bin_soru", title: "Bin Soru Yolda",
                    detail: "Toplamda 1000 soru çözdün.", subject: nil, unlockedAt: nil),
        Achievement(id: "zamanla_yaris", title: "Zamanla Yarış",
                    detail: "Süreli bir tam denemeyi süre dolmadan bitirdin.", subject: nil, unlockedAt: nil),
        Achievement(id: "yedi_gun", title: "Yedi Gün Üst Üste",
                    detail: "Yedi gün boyunca her gün en az bir soru çözdün.", subject: nil, unlockedAt: nil),
        Achievement(id: "ilk_asama", title: "Yola Çıktın",
                    detail: "Yolculuk'ta ilk aşamanı geçtin.", subject: nil, unlockedAt: nil),
        Achievement(id: "on_asama", title: "Yol Alıyorsun",
                    detail: "Yolculuk'ta toplam 10 aşama geçtin.", subject: nil, unlockedAt: nil),
    ]

    static func template(id: String) -> Achievement? {
        all.first { $0.id == id }
    }
}
