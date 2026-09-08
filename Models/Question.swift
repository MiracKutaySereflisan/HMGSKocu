// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import Foundation

/// HMGS'nin ders alanları. Ham değerler (`rawValue`) `seed_questions.json` içindeki
/// `subject` alanıyla birebir aynı — bu yüzden JSON çözümlemesi ekstra eşleme
/// koduna ihtiyaç duymuyor. Bu ham değerler KAYITLI VERİDE de kullanılıyor
/// (QuestionStat, JourneyStageLayout), o yüzden bir kez yayınlandıktan sonra
/// **asla değiştirilmemeli** — değişirse kullanıcıların ilerlemesi kaybolur.
///
/// 20 tanesi resmî HMGS dersi (bkz. `officialExamWeight`). Dört tanesi
/// (avrupaBirligiHukuku, insanHaklariHukuku, fikriSinaiHaklar, adliBilisim) resmî
/// müfredat dışı ek pratik dersleri: "Ders Bazlı Seçim"de tek başına seçilebilirler
/// ama ağırlıklı "Tüm HMGS Müfredatı" denemesine dahil edilmezler.
enum LegalSubject: String, Codable, CaseIterable, Identifiable, Sendable {
    case medeniHukuk = "medeni_hukuk"
    case borclarHukuku = "borclar_hukuku"
    case ticaretHukuku = "ticaret_hukuku"
    case anayasaHukuku = "anayasa_hukuku"
    case anayasaYargisi = "anayasa_yargisi"
    case idareHukuku = "idare_hukuku"
    case idariYargilamaUsulu = "idari_yargilama_usulu"
    case cezaHukuku = "ceza_hukuku"
    case cezaMuhakemesiHukuku = "ceza_muhakemesi_hukuku"
    case medeniUsulHukuku = "medeni_usul_hukuku"
    case icraIflasHukuku = "icra_iflas_hukuku"
    case isHukuku = "is_hukuku"
    case uluslararasiOzelHukuk = "uluslararasi_ozel_hukuk"
    case uluslararasiKamuHukuku = "uluslararasi_kamu_hukuku"
    case vergiHukuku = "vergi_hukuku"
    case vergiUsulHukuku = "vergi_usul_hukuku"
    case hukukFelsefesiSosyolojisi = "hukuk_felsefesi_sosyolojisi"
    case turkHukukTarihi = "turk_hukuk_tarihi"
    case genelKamuHukuku = "genel_kamu_hukuku"
    case notariatMeslekHukuku = "meslek_hukuku_etik"
    // Resmî kotası olmayan ek pratik dersleri — ağırlık 0.
    case avrupaBirligiHukuku = "avrupa_birligi_hukuku"
    case insanHaklariHukuku = "insan_haklari_hukuku"
    case fikriSinaiHaklar = "fikri_sinai_haklar"
    case adliBilisim = "adli_bilisim"

    var id: String { rawValue }

    /// Arayüzde görünen ad — resmî HMGS ders adıyla aynı.
    var displayName: String {
        switch self {
        case .medeniHukuk: return "Medeni Hukuk"
        case .borclarHukuku: return "Borçlar Hukuku"
        case .ticaretHukuku: return "Ticaret Hukuku"
        case .anayasaHukuku: return "Anayasa Hukuku"
        case .anayasaYargisi: return "Anayasa Yargısı"
        case .idareHukuku: return "İdare Hukuku"
        case .idariYargilamaUsulu: return "İdari Yargılama Usulü"
        case .cezaHukuku: return "Ceza Hukuku"
        case .cezaMuhakemesiHukuku: return "Ceza Yargılama Usulü (CMK)"
        case .medeniUsulHukuku: return "Hukuk Yargılama Usulü (HMK)"
        case .icraIflasHukuku: return "İcra ve İflas Hukuku"
        case .isHukuku: return "İş ve Sosyal Güvenlik Hukuku"
        case .uluslararasiOzelHukuk: return "Milletlerarası Özel Hukuk"
        case .uluslararasiKamuHukuku: return "Milletlerarası Hukuk"
        case .vergiHukuku: return "Vergi Hukuku"
        case .vergiUsulHukuku: return "Vergi Usul Hukuku"
        case .hukukFelsefesiSosyolojisi: return "Hukuk Felsefesi ve Sosyolojisi"
        case .turkHukukTarihi: return "Türk Hukuk Tarihi"
        case .genelKamuHukuku: return "Genel Kamu Hukuku"
        case .notariatMeslekHukuku: return "Avukatlık Hukuku"
        case .avrupaBirligiHukuku: return "Avrupa Birliği Hukuku"
        case .insanHaklariHukuku: return "İnsan Hakları Hukuku"
        case .fikriSinaiHaklar: return "Fikri ve Sınai Haklar"
        case .adliBilisim: return "Adli Bilişim"
        }
    }

    /// Resmî 120 soruluk HMGS dağılımındaki soru sayısı. Tabloda olmayan dersler
    /// (yukarıdaki dört bonus ders) 0 döner ve ağırlıklı denemeye girmez.
    static let officialExamWeight: [LegalSubject: Int] = [
        .medeniHukuk: 15,
        .borclarHukuku: 12,
        .ticaretHukuku: 12,
        .medeniUsulHukuku: 12,
        .cezaHukuku: 9,
        .anayasaHukuku: 6,
        .idareHukuku: 6,
        .icraIflasHukuku: 6,
        .cezaMuhakemesiHukuku: 6,
        .isHukuku: 6,
        .anayasaYargisi: 3,
        .idariYargilamaUsulu: 3,
        .vergiHukuku: 3,
        .vergiUsulHukuku: 3,
        .notariatMeslekHukuku: 3,
        .hukukFelsefesiSosyolojisi: 3,
        .turkHukukTarihi: 3,
        .uluslararasiKamuHukuku: 3,
        .uluslararasiOzelHukuk: 3,
        .genelKamuHukuku: 3,
    ]

    /// Tam bir HMGS denemesindeki toplam soru sayısı (officialExamWeight toplamı) — 120.
    static let officialExamTotal = officialExamWeight.values.reduce(0, +)

    var officialWeight: Int { Self.officialExamWeight[self] ?? 0 }
    var isOfficialHMGSSubject: Bool { officialWeight > 0 }

    /// Ders seçicilerde ve listelerde her derse görsel kimlik veren küçük simge.
    var journeyIcon: String {
        switch self {
        case .medeniHukuk, .medeniUsulHukuku: return "person.2.fill"
        case .borclarHukuku, .icraIflasHukuku: return "doc.text.fill"
        case .ticaretHukuku: return "building.2.fill"
        case .anayasaHukuku, .anayasaYargisi, .genelKamuHukuku: return "building.columns.fill"
        case .idareHukuku, .idariYargilamaUsulu: return "checkmark.seal.fill"
        case .cezaHukuku, .cezaMuhakemesiHukuku: return "exclamationmark.shield.fill"
        case .isHukuku: return "briefcase.fill"
        case .uluslararasiOzelHukuk, .uluslararasiKamuHukuku, .avrupaBirligiHukuku: return "globe"
        case .vergiHukuku, .vergiUsulHukuku: return "percent"
        case .hukukFelsefesiSosyolojisi, .turkHukukTarihi: return "book.closed.fill"
        case .notariatMeslekHukuku: return "signature"
        case .insanHaklariHukuku: return "hand.raised.fill"
        case .fikriSinaiHaklar: return "lightbulb.fill"
        case .adliBilisim: return "desktopcomputer"
        }
    }

    /// Ders listesini her yerde aynı sırayla göstermek için tek kaynak:
    /// önce resmî dersler (sınavdaki ağırlığı yüksekten düşüğe), sonra bonus dersler.
    /// Alfabetik karşılaştırma Türkçe'ye göre yapılıyor (İ/ı doğru sıralansın diye).
    static let displayOrdered: [LegalSubject] = LegalSubject.allCases.sorted { lhs, rhs in
        if lhs.isOfficialHMGSSubject != rhs.isOfficialHMGSSubject {
            return lhs.isOfficialHMGSSubject && !rhs.isOfficialHMGSSubject
        }
        if lhs.officialWeight != rhs.officialWeight { return lhs.officialWeight > rhs.officialWeight }
        return lhs.displayName.compare(rhs.displayName, options: [], range: nil, locale: Locale.turkish) == .orderedAscending
    }
}

enum Difficulty: String, Codable, CaseIterable, Sendable {
    case kolay, orta, zor

    var displayName: String {
        switch self {
        case .kolay: return "Kolay"
        case .orta: return "Orta"
        case .zor: return "Zor"
        }
    }

    /// Kolay → Orta → Zor sırası. Aşamaları zorluk artan şekilde dizmek için
    /// tek kaynak; birden fazla yerde ayrı ayrı tanımlanmıyor.
    var sortOrder: Int {
        switch self {
        case .kolay: return 0
        case .orta: return 1
        case .zor: return 2
        }
    }
}

/// Beş şıklı tek bir çoktan seçmeli soru.
///
/// İÇERİK KAYNAĞI — önemli: `Resources/seed_questions.json` içindeki soruların
/// tamamı bu uygulama için özel olarak hazırlanmış çalışma sorularıdır; resmî
/// çıkmış HMGS soruları DEĞİLDİR ve kullanıcıya öyle sunulmaz (bkz.
/// `ContentPolicy` ve Profil > İçerik Hakkında ekranı).
struct Question: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var subject: LegalSubject
    var difficulty: Difficulty
    var topicTag: String
    var prompt: String
    var options: [String]         // tam olarak 5 şık, 0...4 == A...E
    var correctOptionIndex: Int
    var explanation: String
    var lawReference: String?
    /// Yalnızca bir insanın gerçek, kaynağı belirtilmiş çıkmış soruyla doğruladığı
    /// sorularda true olur. Şu an tüm sorularda false.
    var isVerifiedPastExamQuestion: Bool
    var examYear: Int?

    /// Eski kayıtlarda olmayan alanlar eklendiğinde çözümleme kırılmasın diye
    /// açık bir `init(from:)`. Zorunlu alanlar eksikse soru geçersizdir ve
    /// `SeedQuestionLoader` tarafından elenir.
    enum CodingKeys: String, CodingKey {
        case id, subject, difficulty, topicTag, prompt, options
        case correctOptionIndex, explanation, lawReference
        case isVerifiedPastExamQuestion, examYear
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        subject = try c.decode(LegalSubject.self, forKey: .subject)
        difficulty = try c.decodeIfPresent(Difficulty.self, forKey: .difficulty) ?? .orta
        topicTag = try c.decodeIfPresent(String.self, forKey: .topicTag) ?? ""
        prompt = try c.decode(String.self, forKey: .prompt)
        options = try c.decode([String].self, forKey: .options)
        correctOptionIndex = try c.decode(Int.self, forKey: .correctOptionIndex)
        explanation = try c.decodeIfPresent(String.self, forKey: .explanation) ?? ""
        lawReference = try c.decodeIfPresent(String.self, forKey: .lawReference)
        isVerifiedPastExamQuestion = try c.decodeIfPresent(Bool.self, forKey: .isVerifiedPastExamQuestion) ?? false
        examYear = try c.decodeIfPresent(Int.self, forKey: .examYear)
    }

    init(
        id: UUID,
        subject: LegalSubject,
        difficulty: Difficulty,
        topicTag: String,
        prompt: String,
        options: [String],
        correctOptionIndex: Int,
        explanation: String,
        lawReference: String?,
        isVerifiedPastExamQuestion: Bool = false,
        examYear: Int? = nil
    ) {
        self.id = id
        self.subject = subject
        self.difficulty = difficulty
        self.topicTag = topicTag
        self.prompt = prompt
        self.options = options
        self.correctOptionIndex = correctOptionIndex
        self.explanation = explanation
        self.lawReference = lawReference
        self.isVerifiedPastExamQuestion = isVerifiedPastExamQuestion
        self.examYear = examYear
    }

    /// Bir soru ancak beş şıkkı varsa, doğru şık indeksi bu şıklardan birini
    /// gösteriyorsa ve soru metni boş değilse gösterilebilir. Bozuk içerik
    /// uygulamayı çökertmek yerine sessizce elenir (bkz. `SeedQuestionLoader`).
    var isWellFormed: Bool {
        options.count == Question.optionCount
            && options.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            && options.indices.contains(correctOptionIndex)
            && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Şık indeksinin harfi. Dizi sınırı dışında bir indekste çökmek yerine "?" döner.
    static func optionLetter(_ index: Int) -> String {
        guard optionLetters.indices.contains(index) else { return "?" }
        return optionLetters[index]
    }

    static let optionLetters = ["A", "B", "C", "D", "E"]
    static let optionCount = 5

    /// Gerçek HMGS oranı: 120 soru / 155 dakika ≈ soru başına 77,5 sn.
    static let secondsPerQuestion: Double = (155.0 * 60.0) / 120.0
}

extension Locale {
    /// Türkçe'ye özgü büyük/küçük harf (İ/ı) ve sıralama davranışı gereken her yerde
    /// kullanılan tek sabit. Cihaz dili İngilizce olsa bile uygulama metinleri
    /// Türkçe olduğu için sabit tutuluyor.
    static let turkish = Locale(identifier: "tr_TR")
}
