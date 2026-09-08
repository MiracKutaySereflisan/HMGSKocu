import Foundation

/// Bir sınav oturumunun kapsamı. `Codable` — kayıtlı oturumlarda saklandığı için
/// case isimleri ve ilişkili değerleri değiştirilirse eski kayıtlar okunamaz hale
/// gelir; değiştirmek gerekirse `LocalStore` içinde göç (migration) yazılmalı.
enum ExamScope: Codable, Hashable, Sendable {
    case fullHMGS                                              // 120 soruluk gerçek dağılım
    case singleSubject(LegalSubject)
    case customMix([LegalSubject])
    case mistakePool(LegalSubject?)                            // nil == tüm konulardaki yanlışlar
    case blankPool(LegalSubject?)                              // nil == tüm konulardaki boşlar
    case journeyStage(subject: LegalSubject, stageIndex: Int)  // Yolculuk'ta tek bir aşama

    var label: String {
        switch self {
        case .fullHMGS: return "Tüm HMGS Müfredatı"
        case .singleSubject(let subject): return subject.displayName
        case .customMix(let list):
            if list.count == 1, let only = list.first { return only.displayName }
            return "Karma Konular"
        case .mistakePool(let subject):
            guard let subject else { return "Tüm Yanlışlarım" }
            return "\(subject.displayName) Yanlışları"
        case .blankPool(let subject):
            guard let subject else { return "Boş Bıraktıklarım" }
            return "\(subject.displayName) Boşları"
        case .journeyStage(let subject, let index): return "\(subject.displayName) — \(index + 1). Aşama"
        }
    }

    var icon: String {
        switch self {
        case .fullHMGS: return "rosette"
        case .singleSubject(let subject): return subject.journeyIcon
        case .customMix: return "square.stack.3d.up.fill"
        case .mistakePool: return "exclamationmark.triangle.fill"
        case .blankPool: return "questionmark.circle.fill"
        case .journeyStage(let subject, _): return subject.journeyIcon
        }
    }

    /// Bu kapsam, sonuç ekranında HMGS barajıyla kıyaslanmalı mı?
    /// Yalnızca tam müfredat denemesinde baraj anlamlı.
    var comparesToHMGSThreshold: Bool {
        if case .fullHMGS = self { return true }
        return false
    }

    /// Hata havuzundan gelen tekrar çözümleri istatistiklere "yeni deneme" olarak
    /// girse de ana sayfadaki "son denemeler" listesini doldurmasın diye ayrılıyor.
    var isRetakeScope: Bool {
        switch self {
        case .mistakePool, .blankPool: return true
        default: return false
        }
    }
}

enum TimeMode: String, Codable, Hashable, Sendable {
    case hmgsStandard   // questionCount * Question.secondsPerQuestion
    case untimed        // sınır yok; geçen süre yine de kaydedilir
}

/// "Sınav Ayarları" ekranında seçilen, oturum başlamadan önceki yapılandırma.
struct ExamConfiguration: Hashable, Identifiable, Sendable {
    /// Her başlatmada benzersiz — aynı ayarlarla ikinci kez sınava girildiğinde
    /// SwiftUI'ın `navigationDestination(item:)` tetiklenmemesi hatasını önler.
    let id = UUID()
    var scope: ExamScope
    var questionCount: Int
    var timeMode: TimeMode

    var timeLimitSeconds: Int? {
        switch timeMode {
        case .hmgsStandard:
            return Int((Double(questionCount) * Question.secondsPerQuestion).rounded())
        case .untimed:
            return nil
        }
    }
}

/// Bir sınavı başlatmak için gereken her şeyi taşıyan tek paket.
///
/// Neden ayrı bir tip: SwiftUI'da aynı ekranda aynı TİPTE iki
/// `navigationDestination(item:)` tanımlanamaz — ikincisi sessizce çalışmaz.
/// Ana sayfada hem "yeni sınav" hem "yarım kalanı sürdür" olduğu için ikisini tek
/// tipte birleştirmek zorundayız. Yan faydası: soru listesi ile yapılandırma artık
/// TEK adımda atanıyor, eskiden iki ayrı `@State` sırayla set ediliyordu ve
/// yanlış sırada set edilirse boş listeyle sınav başlayabiliyordu.
struct ExamLaunch: Identifiable, Hashable {
    let id = UUID()
    var configuration: ExamConfiguration
    /// Hata havuzu tekrarı ya da Yolculuk aşaması gibi, soruları önceden belli olan akışlar.
    var explicitQuestionIDs: [UUID]?
    /// Yarım kalmış bir sınav sürdürülüyorsa onun anlık görüntüsü.
    var resuming: InProgressExam?

    static func == (lhs: ExamLaunch, rhs: ExamLaunch) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    init(configuration: ExamConfiguration, explicitQuestionIDs: [UUID]? = nil, resuming: InProgressExam? = nil) {
        self.configuration = configuration
        self.explicitQuestionIDs = explicitQuestionIDs
        self.resuming = resuming
    }
}

/// Sınav içinde cevaplanmış (ya da boş bırakılmış) tek bir soru.
struct AnswerRecord: Codable, Hashable, Sendable {
    let questionID: UUID
    var selectedOptionIndex: Int?   // nil == boş bırakıldı
    var isCorrect: Bool?            // puanlanana kadar nil
    var timeSpentSeconds: Double
}

/// Tamamlanmış bir sınav: kaydedilmeye, hata havuzunu ve başarımları beslemeye hazır.
struct ExamSession: Codable, Identifiable, Sendable {
    let id: UUID
    let scope: ExamScope
    let startedAt: Date
    var finishedAt: Date?
    var answers: [AnswerRecord]
    var timeMode: TimeMode
    var timeLimitSeconds: Int?
    /// Sınav süresince gerçekten geçen süre. `finishedAt - startedAt` yerine bunu
    /// kullanıyoruz: kullanıcı sınav sırasında cihaz saatini değiştirirse ya da
    /// yaz saati geçişi olursa fark saçmalayabiliyor.
    var measuredElapsedSeconds: Double

    // Not: `count(where:)` bilinçli olarak kullanılmıyor — o API Swift 6 standart
    // kütüphanesiyle geldi ve iOS 18 gerektiriyor; bu uygulama iOS 17'yi destekliyor.
    var correctCount: Int { answers.filter { $0.isCorrect == true }.count }
    var wrongCount: Int { answers.filter { $0.isCorrect == false }.count }
    var blankCount: Int { answers.filter { $0.selectedOptionIndex == nil }.count }
    var totalCount: Int { answers.count }

    /// HMGS puanlama kuralı: yanlış doğruyu götürmez, sadece doğrular sayılır.
    /// 100 üzerinden puan (doğru / toplam × 100) — kullanıcı 20 soruluk konu testi
    /// de çözebildiği için her zaman orantısal hesaplanıyor.
    var scoreOutOf100: Double {
        guard totalCount > 0 else { return 0 }
        return (Double(correctCount) / Double(totalCount)) * 100.0
    }

    var passesHMGSThreshold: Bool { scoreOutOf100 >= ScoringEngine.hmgsPassThresholdOutOf100 }

    var elapsedSeconds: Double { max(0, measuredElapsedSeconds) }

    /// Eski kayıtlarda `measuredElapsedSeconds` yok — o kayıtlar için
    /// `finishedAt - startedAt` farkına düşülüyor (negatifse 0).
    enum CodingKeys: String, CodingKey {
        case id, scope, startedAt, finishedAt, answers, timeMode, timeLimitSeconds, measuredElapsedSeconds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        scope = try c.decode(ExamScope.self, forKey: .scope)
        startedAt = try c.decode(Date.self, forKey: .startedAt)
        finishedAt = try c.decodeIfPresent(Date.self, forKey: .finishedAt)
        answers = try c.decode([AnswerRecord].self, forKey: .answers)
        timeMode = try c.decode(TimeMode.self, forKey: .timeMode)
        timeLimitSeconds = try c.decodeIfPresent(Int.self, forKey: .timeLimitSeconds)
        if let measured = try c.decodeIfPresent(Double.self, forKey: .measuredElapsedSeconds) {
            measuredElapsedSeconds = measured
        } else if let finishedAt {
            measuredElapsedSeconds = max(0, finishedAt.timeIntervalSince(startedAt))
        } else {
            measuredElapsedSeconds = 0
        }
    }

    init(
        id: UUID,
        scope: ExamScope,
        startedAt: Date,
        finishedAt: Date?,
        answers: [AnswerRecord],
        timeMode: TimeMode,
        timeLimitSeconds: Int?,
        measuredElapsedSeconds: Double
    ) {
        self.id = id
        self.scope = scope
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.answers = answers
        self.timeMode = timeMode
        self.timeLimitSeconds = timeLimitSeconds
        self.measuredElapsedSeconds = measuredElapsedSeconds
    }
}

/// Yarım kalmış bir sınavın diske yazılan görüntüsü. Telefon çalınca, uygulama
/// arka plana atılınca ya da iOS uygulamayı bellekten atınca kullanıcının 40
/// soruluk emeği buharlaşmasın diye her cevapta güncelleniyor.
struct InProgressExam: Codable, Sendable {
    let scope: ExamScope
    let timeMode: TimeMode
    let timeLimitSeconds: Int?
    let questionIDs: [UUID]
    var answers: [UUID: Int]
    var questionElapsedSeconds: [UUID: Double]
    var currentIndex: Int
    var elapsedSeconds: Double
    let startedAt: Date
    var savedAt: Date

    /// Çok eski bir yarım sınav teklif edilmesin — 24 saatten eskiyse anlamını yitiriyor.
    var isStillOfferable: Bool {
        Date().timeIntervalSince(savedAt) < 24 * 60 * 60 && !questionIDs.isEmpty
    }

    var answeredCount: Int { answers.count }
}
