import XCTest
@testable import HMGSKocu

/// İÇERİK KALİTE KAPISI.
///
/// `SeedContentTests` sorunun BOZUK olup olmadığına bakar (5 şık var mı, indeks
/// geçerli mi). Bu dosya ise sorunun İYİ olup olmadığına bakar: açıklama
/// öğretiyor mu, dayanağı yazılı mı, doğru cevap şıkkın uzunluğundan tahmin
/// edilebiliyor mu.
///
/// Eşikler bilinçli olarak iki kademeli:
/// - **Taban** (bu dosya): mevcut havuzun altına düşmemesi gereken sınır.
///   Kırmızı yanarsa içerik kalitesi GERİLEMİŞ demektir.
/// - **Tam standart**: yeni üretilen her parti için `Tools/soru_denetim.py`
///   tarafından uygulanır ve çok daha katıdır (açıklama ≥380 karakter,
///   "doğru şık en uzun" oranı ≤%40).
///
/// Yani: bu testler geriye dönük borcu tolere eder ama büyümesine izin vermez;
/// yeni içerik ise gerçek standarda tabidir.
final class ContentQualityTests: XCTestCase {

    private func loadPool() throws -> [Question] {
        if let pool = try? SeedQuestionLoader.loadAll(bundle: Bundle(for: ContentQualityTests.self)) {
            return pool
        }
        return try SeedQuestionLoader.loadAll(bundle: .main)
    }

    // MARK: - Dayanak

    /// Dayanaksız soru olmaz: her sorunun hangi kurala dayandığı yazılı olmalı.
    func testEveryQuestionCitesItsBasis() throws {
        for question in try loadPool() {
            let reference = question.lawReference?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            XCTAssertFalse(reference.isEmpty, "Dayanağı yazılmamış soru: \(question.id)")
        }
    }

    /// Madde referansı verilmiş bir soruda açıklama da o maddeye değinmeli —
    /// yoksa kullanıcı "neden böyle" sorusunun cevabını bulamaz.
    func testExplanationsMentionTheArticleWhenOneIsCited() throws {
        let pool = try loadPool()
        let withArticle = pool.filter { ($0.lawReference ?? "").range(of: #"m\.\s*\d+"#, options: .regularExpression) != nil }
        let mentioning = withArticle.filter { $0.explanation.range(of: #"m\.\s*\d+"#, options: .regularExpression) != nil }

        guard !withArticle.isEmpty else { return }
        let ratio = Double(mentioning.count) / Double(withArticle.count)
        XCTAssertGreaterThan(
            ratio, 0.85,
            "Madde referanslı soruların yalnızca \(Format.percent(ratio))'inde açıklama maddeye değiniyor"
        )
    }

    // MARK: - Açıklama

    /// Açıklama, cevabı tekrarlamaktan ibaret olamaz.
    func testNoExplanationIsTrivial() throws {
        for question in try loadPool() {
            XCTAssertGreaterThanOrEqual(
                question.explanation.count, 40,
                "Açıklama çok kısa (\(question.explanation.count) karakter): \(question.topicTag)"
            )
        }
    }

    /// Açıklama, telefonda okunamayacak kadar uzun da olamaz.
    func testNoExplanationIsBloated() throws {
        for question in try loadPool() {
            XCTAssertLessThanOrEqual(
                question.explanation.count, 1200,
                "Açıklama çok uzun (\(question.explanation.count) karakter): \(question.topicTag)"
            )
        }
    }

    /// Havuz genelinde açıklamalar öğretici uzunlukta olmalı. Bu eşik, içerik
    /// zenginleştirme turlarıyla kademeli olarak yükseltilir.
    func testAverageExplanationIsSubstantial() throws {
        let pool = try loadPool()
        let average = pool.reduce(0) { $0 + $1.explanation.count } / max(1, pool.count)
        XCTAssertGreaterThan(average, 200, "Ortalama açıklama uzunluğu düşmüş: \(average) karakter")
    }

    // MARK: - Şık dengesi

    /// Doğru cevap sistematik olarak en uzun şık olursa, kullanıcı soruyu
    /// okumadan tahmin etmeye başlar ve uygulama çalışma değerini yitirir.
    /// Rastgele dağılımda beklenen oran %20'dir.
    func testCorrectAnswerIsNotSystematicallyTheLongestOption() throws {
        let pool = try loadPool()
        let longestIsCorrect = pool.filter { question in
            guard let longest = question.options.map(\.count).max(),
                  question.options.indices.contains(question.correctOptionIndex) else { return false }
            return question.options[question.correctOptionIndex].count == longest
        }
        let ratio = Double(longestIsCorrect.count) / Double(max(1, pool.count))
        XCTAssertLessThan(
            ratio, 0.75,
            "Soruların \(Format.percent(ratio))'inde doğru cevap en uzun şık — tahmin edilebilir hâle geliyor"
        )
    }

    /// Şıklardan biri diğerlerinin katı uzunlukta olmamalı.
    func testNoOptionIsAbsurdlyLong() throws {
        for question in try loadPool() {
            for option in question.options {
                XCTAssertLessThanOrEqual(option.count, 400, "Şık çok uzun: \(question.topicTag)")
            }
        }
    }

    /// "Hiçbiri" / "Hepsi" şıkları kullanılmaz: ölçme değeri düşüktür ve
    /// diğer şıkları anlamsızlaştırır.
    func testNoAllOrNoneOptions() throws {
        let forbidden = ["hiçbiri", "hepsi", "yukarıdakilerin hepsi", "yukarıdakilerin hiçbiri"]
        for question in try loadPool() {
            for option in question.options {
                let normalized = option.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(with: Locale.turkish)
                XCTAssertFalse(forbidden.contains(normalized), "Yasak şık: \(question.topicTag)")
            }
        }
    }

    // MARK: - Soru kökü

    func testPromptsAreReadableOnAPhone() throws {
        for question in try loadPool() {
            XCTAssertLessThanOrEqual(question.prompt.count, 400, "Soru kökü çok uzun: \(question.topicTag)")
            XCTAssertGreaterThanOrEqual(question.prompt.count, 20, "Soru kökü çok kısa: \(question.topicTag)")
        }
    }

    /// Olumsuz köklü ("…DEĞİLDİR") soru bir ölçme aracıdır, bir alışkanlık değil.
    func testNegativeStemsStayAMinority() throws {
        let pool = try loadPool()
        let negative = pool.filter {
            $0.prompt.range(of: "DEĞİLDİR|OLUŞTURMAZ|YANLIŞTIR|OLAMAZ|SAYILMAZ", options: .regularExpression) != nil
        }
        let ratio = Double(negative.count) / Double(max(1, pool.count))
        XCTAssertLessThan(ratio, 0.20, "Olumsuz köklü soru oranı çok yüksek: \(Format.percent(ratio))")
    }

    // MARK: - Sınıflandırma

    /// Ders etiketi uygulamanın tanıdığı 24 değerden biri olmalı — aksi hâlde
    /// soru hiçbir ekranda görünmez. (Çözümleyici bozuk kaydı zaten eler, bu
    /// test elenmiş soru olmadığını doğrular.)
    func testEveryQuestionHasARecognizedSubject() throws {
        let pool = try loadPool()
        let known = Set(LegalSubject.allCases)
        for question in pool {
            XCTAssertTrue(known.contains(question.subject), "Tanınmayan ders: \(question.id)")
        }
        try XCTSkipIf(pool.count < 600, "Havuz boyutu kontrolü tam havuzu ister; örnek havuzda atlanır.")
        XCTAssertGreaterThan(pool.count, 690, "Havuz beklenenden küçük — sorular sessizce elenmiş olabilir")
    }

    /// Alt konu etiketi hem Yolculuk aşamasının başlığı hem de içerik haritası
    /// için kullanılıyor; boş ya da ekranı taşıracak kadar uzun olamaz.
    func testTopicTagsAreUsable() throws {
        for question in try loadPool() {
            let tag = question.topicTag.trimmingCharacters(in: .whitespacesAndNewlines)
            XCTAssertFalse(tag.isEmpty, "Boş konu etiketi: \(question.id)")
            XCTAssertLessThanOrEqual(tag.count, 60, "Konu etiketi çok uzun: \(tag)")
        }
    }

    /// Aynı dayanaktan çok sayıda soru, havuzun dar bir alanda yığılması demektir.
    func testNoSingleArticleDominatesThePool() throws {
        let pool = try loadPool()
        var counts: [String: Int] = [:]
        for question in pool {
            let reference = question.lawReference ?? "—"
            counts[reference, default: 0] += 1
        }
        for (reference, count) in counts {
            XCTAssertLessThanOrEqual(count, 10, "Aynı dayanaktan \(count) soru var: \(reference)")
        }
    }

    // MARK: - Ders dengesi

    /// Resmî HMGS derslerinin her birinde, bir Yolculuk aşamasını dolduracak
    /// kadar soru bulunmalı. Hedef ders başına 50; bu test alt sınırı korur.
    func testEveryOfficialSubjectHasAWorkableMinimum() throws {
        let pool = try loadPool()
        try XCTSkipIf(pool.count < 600, "Ders başına alt sınır tam havuzu ister; örnek havuzda atlanır.")
        var counts: [LegalSubject: Int] = [:]
        for question in pool { counts[question.subject, default: 0] += 1 }

        for subject in LegalSubject.allCases where subject.isOfficialHMGSSubject {
            let count = counts[subject] ?? 0
            XCTAssertGreaterThanOrEqual(
                count, 16,
                "\(subject.displayName) dersinde yalnızca \(count) soru var (iki aşama bile çıkmaz)"
            )
        }
    }
}
