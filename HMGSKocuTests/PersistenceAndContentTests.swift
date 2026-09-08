// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import XCTest
@testable import HMGSKocu

/// GÖÇ (migration) TESTLERİ — bunlar olmadan sürüm çıkarılmaz.
/// En sık veri kaybı sebebi: yeni alan eklenince eski kayıtların çözümlenememesi.
/// Aşağıdaki JSON'lar bilerek "eski sürümden kalmış" biçimde yazıldı.
final class MigrationTests: XCTestCase {

    func testLegacyQuestionStatWithoutNewFieldsStillDecodes() throws {
        // v1 öncesi kayıt: blank, wasLastAttemptBlank, reclaimedCount yok.
        let legacy = """
        [{
          "questionID": "11111111-1111-4111-8111-111111111111",
          "subject": "medeni_hukuk",
          "attempts": 3,
          "correct": 1,
          "wrong": 2,
          "lastAttemptDate": "2026-01-15T10:00:00Z",
          "isInMistakePool": true
        }]
        """.data(using: .utf8) ?? Data()

        let stats = try JSONDecoder.hmgs.decode([QuestionStat].self, from: legacy)
        XCTAssertEqual(stats.count, 1)
        XCTAssertEqual(stats[0].attempts, 3)
        XCTAssertEqual(stats[0].blank, 0)
        XCTAssertFalse(stats[0].wasLastAttemptBlank)
        XCTAssertEqual(stats[0].reclaimedCount, 0)
        XCTAssertTrue(stats[0].isInMistakePool, "Havuz durumu korunmalı")
    }

    func testLegacyExamSessionWithoutMeasuredElapsedDecodes() throws {
        let legacy = """
        {
          "id": "22222222-2222-4222-8222-222222222222",
          "scope": { "fullHMGS": {} },
          "startedAt": "2026-01-15T10:00:00Z",
          "finishedAt": "2026-01-15T10:30:00Z",
          "answers": [],
          "timeMode": "untimed"
        }
        """.data(using: .utf8) ?? Data()

        let session = try JSONDecoder.hmgs.decode(ExamSession.self, from: legacy)
        // measuredElapsedSeconds yoksa finishedAt - startedAt farkına düşülüyor.
        XCTAssertEqual(session.elapsedSeconds, 1800, accuracy: 1)
    }

    func testQuestionStatRoundTrip() throws {
        let original = TestFixtures.stat(questionID: UUID(), inMistakePool: true, wasBlank: true)
        let data = try JSONEncoder.hmgs.encode([original])
        let decoded = try JSONDecoder.hmgs.decode([QuestionStat].self, from: data)
        XCTAssertEqual(decoded.first, original)
    }

    func testExamScopeRoundTripForEveryCase() throws {
        let scopes: [ExamScope] = [
            .fullHMGS,
            .singleSubject(.medeniHukuk),
            .customMix([.cezaHukuku, .isHukuku]),
            .mistakePool(nil),
            .mistakePool(.vergiHukuku),
            .blankPool(nil),
            .journeyStage(subject: .ticaretHukuku, stageIndex: 4)
        ]
        for scope in scopes {
            let data = try JSONEncoder.hmgs.encode(scope)
            let decoded = try JSONDecoder.hmgs.decode(ExamScope.self, from: data)
            XCTAssertEqual(decoded, scope, "\(scope.label) kaydedilip geri okunamıyor")
        }
    }

    func testJourneyLayoutRoundTrip() throws {
        let pool = TestFixtures.questions(count: 17, subject: .medeniHukuk)
        try XCTSkipIf(pool.count < 600, "Yolculuk aşamaları tam havuzu ister; örnek havuzda atlanır.")
        let layout = JourneyCatalogue.reconcile(layout: JourneyStageLayout(), pool: pool)
        let data = try JSONEncoder.hmgs.encode(layout)
        let decoded = try JSONDecoder.hmgs.decode(JourneyStageLayout.self, from: data)
        XCTAssertEqual(decoded, layout)
    }

    func testInProgressExamExpiresAfterADay() throws {
        let fresh = InProgressExam(
            scope: .fullHMGS, timeMode: .untimed, timeLimitSeconds: nil,
            questionIDs: [UUID()], answers: [:], questionElapsedSeconds: [:],
            currentIndex: 0, elapsedSeconds: 10,
            startedAt: Date(), savedAt: Date()
        )
        XCTAssertTrue(fresh.isStillOfferable)

        let stale = InProgressExam(
            scope: .fullHMGS, timeMode: .untimed, timeLimitSeconds: nil,
            questionIDs: [UUID()], answers: [:], questionElapsedSeconds: [:],
            currentIndex: 0, elapsedSeconds: 10,
            startedAt: Date().addingTimeInterval(-90_000),
            savedAt: Date().addingTimeInterval(-90_000)
        )
        XCTAssertFalse(stale.isStillOfferable, "25 saat önceki yarım sınav teklif edilmemeli")
    }
}

/// Soru çözümleyicisinin bozuk içeriğe dayanıklılığı.
final class SeedQuestionLoaderTests: XCTestCase {

    func testBrokenEntryDoesNotKillTheWholePool() throws {
        let json = """
        [
          {"id":"33333333-3333-4333-8333-333333333333","subject":"medeni_hukuk","difficulty":"orta",
           "topicTag":"T","prompt":"Geçerli soru","options":["1","2","3","4","5"],
           "correctOptionIndex":2,"explanation":"E","lawReference":"TMK m.1",
           "isVerifiedPastExamQuestion":false,"examYear":null},
          {"id":"BOZUK","subject":"medeni_hukuk"},
          {"id":"44444444-4444-4444-8444-444444444444","subject":"medeni_hukuk","difficulty":"orta",
           "topicTag":"T","prompt":"Üç şıklı bozuk soru","options":["1","2","3"],
           "correctOptionIndex":0,"explanation":"E","lawReference":null,
           "isVerifiedPastExamQuestion":false,"examYear":null},
          {"id":"55555555-5555-4555-8555-555555555555","subject":"ceza_hukuku","difficulty":"zor",
           "topicTag":"T","prompt":"Doğru şıkkı olmayan soru","options":["1","2","3","4","5"],
           "correctOptionIndex":9,"explanation":"E","lawReference":null,
           "isVerifiedPastExamQuestion":false,"examYear":null}
        ]
        """.data(using: .utf8) ?? Data()

        let questions = try SeedQuestionLoader.decode(json)
        XCTAssertEqual(questions.count, 1, "Yalnızca geçerli soru kalmalı")
        XCTAssertEqual(questions.first?.prompt, "Geçerli soru")
    }

    func testDuplicateIDsAreDroppedNotDuplicated() throws {
        let json = """
        [
          {"id":"66666666-6666-4666-8666-666666666666","subject":"medeni_hukuk","difficulty":"orta",
           "topicTag":"T","prompt":"İlk","options":["1","2","3","4","5"],"correctOptionIndex":0,
           "explanation":"E","lawReference":null,"isVerifiedPastExamQuestion":false,"examYear":null},
          {"id":"66666666-6666-4666-8666-666666666666","subject":"medeni_hukuk","difficulty":"orta",
           "topicTag":"T","prompt":"İkinci","options":["1","2","3","4","5"],"correctOptionIndex":1,
           "explanation":"E","lawReference":null,"isVerifiedPastExamQuestion":false,"examYear":null}
        ]
        """.data(using: .utf8) ?? Data()

        let questions = try SeedQuestionLoader.decode(json)
        XCTAssertEqual(questions.count, 1)
        XCTAssertEqual(questions.first?.prompt, "İlk")
    }

    func testEmptyPoolThrows() {
        XCTAssertThrowsError(try SeedQuestionLoader.decode(Data("[]".utf8)))
    }
}

/// Uygulamayla birlikte gelen GERÇEK soru havuzunun denetimi.
/// Bir içerik güncellemesi bozuk soru getirirse bu testler kırmızı yanar —
/// hatalı içerik App Store'a değil, buraya çarpar.
final class SeedContentTests: XCTestCase {

    /// Soru dosyası uygulama paketinde; test paketi uygulamayı barındırdığı için
    /// önce test paketine, bulunamazsa ana pakete bakıyoruz. İkisinde de yoksa
    /// test başarısız olur — bu da doğru davranış, çünkü dosya bundle'a
    /// eklenmemişse uygulama da çalışmaz.
    private func loadPool() throws -> [Question] {
        if let pool = try? SeedQuestionLoader.loadAll(bundle: Bundle(for: SeedContentTests.self)) {
            return pool
        }
        return try SeedQuestionLoader.loadAll(bundle: .main)
    }

    func testBundledPoolLoads() throws {
        let pool = try loadPool()
        XCTAssertFalse(pool.isEmpty, "Soru havuzu yüklenemedi")
        try XCTSkipIf(pool.count < 600, "Tam havuz boyutu kontrolü; örnek havuzda atlanır.")
        XCTAssertGreaterThan(pool.count, 600, "Havuzda beklenenden az soru var — dosya eksik kopyalanmış olabilir")
    }

    func testEveryQuestionIsWellFormed() throws {
        for question in try loadPool() {
            XCTAssertTrue(question.isWellFormed, "Bozuk soru: \(question.id)")
            XCTAssertEqual(question.options.count, 5, "5 şık olmalı: \(question.id)")
            XCTAssertFalse(question.explanation.isEmpty, "Açıklama boş: \(question.id)")
        }
    }

    func testNoDuplicateIDsOrPrompts() throws {
        let pool = try loadPool()
        XCTAssertEqual(Set(pool.map(\.id)).count, pool.count, "Aynı id iki soruda")

        let prompts = pool.map { $0.prompt.trimmingCharacters(in: .whitespacesAndNewlines) }
        XCTAssertEqual(Set(prompts).count, prompts.count, "Aynı soru metni iki kez var")
    }

    func testNoDuplicateOptionsWithinAQuestion() throws {
        for question in try loadPool() {
            let normalized = Set(question.options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(with: Locale.turkish) })
            XCTAssertEqual(normalized.count, question.options.count, "Aynı şık iki kez: \(question.id)")
        }
    }

    /// Doğru cevap hep aynı harfte toplanırsa kullanıcı soruyu okumadan tahmin
    /// edebilir hale gelir. Hiçbir harf %30'u geçmemeli.
    func testCorrectAnswerDistributionIsBalanced() throws {
        let pool = try loadPool()
        var counts = [Int](repeating: 0, count: 5)
        for question in pool where question.options.indices.contains(question.correctOptionIndex) {
            counts[question.correctOptionIndex] += 1
        }
        for (index, count) in counts.enumerated() {
            let ratio = Double(count) / Double(pool.count)
            XCTAssertLessThan(ratio, 0.30, "\(Question.optionLetter(index)) şıkkı fazla sık doğru: \(Format.percent(ratio))")
            XCTAssertGreaterThan(ratio, 0.10, "\(Question.optionLetter(index)) şıkkı fazla nadir doğru")
        }
    }

    /// İçeriğin hiçbir yerinde "çıkmış soru" iddiası olmamalı — hem doğru olmadığı
    /// için hem de App Store 2.3 (yanıltıcı tanıtım) riski taşıdığı için.
    func testNoQuestionClaimsToBeAPastExamQuestion() throws {
        for question in try loadPool() {
            XCTAssertFalse(question.isVerifiedPastExamQuestion,
                           "Doğrulanmamış soru 'çıkmış soru' olarak işaretlenmiş: \(question.id)")
            XCTAssertNil(question.examYear)
        }
    }

    func testEveryOfficialSubjectHasQuestions() throws {
        let pool = try loadPool()
        try XCTSkipIf(pool.count < 600, "Ders başına alt sınır tam havuzu ister; örnek havuzda atlanır.")
        let bySubject = Dictionary(grouping: pool, by: \.subject)
        for subject in LegalSubject.allCases where subject.isOfficialHMGSSubject {
            let count = bySubject[subject]?.count ?? 0
            XCTAssertGreaterThanOrEqual(count, 8, "\(subject.displayName) dersinde bir aşamayı dolduracak kadar soru yok (\(count))")
        }
    }

    /// Havuzdaki her ders, Yolculuk'ta en az bir aşama üretebilmeli.
    func testJourneyCanBeBuiltFromRealContent() throws {
        let pool = try loadPool()
        try XCTSkipIf(pool.count < 600, "Yolculuk aşamaları tam havuzu ister; örnek havuzda atlanır.")
        let layout = JourneyCatalogue.reconcile(layout: JourneyStageLayout(), pool: pool)
        var totalStages = 0
        for subject in LegalSubject.allCases {
            let stages = JourneyCatalogue.stages(for: subject, layout: layout, pool: pool)
            totalStages += stages.count
            if (pool.filter { $0.subject == subject }.count) >= 8 {
                XCTAssertFalse(stages.isEmpty, "\(subject.displayName) için aşama üretilemedi")
            }
        }
        XCTAssertGreaterThan(totalStages, 60)
    }

    /// Tam deneme gerçekten 120 soru çekebiliyor mu?
    func testFullExamCanBeAssembledFromRealContent() throws {
        let pool = try loadPool()
        try XCTSkipIf(pool.count < 600, "120 soruluk tam deneme tam havuzu ister; örnek havuzda atlanır.")
        let selected = QuestionSelector.weightedFullCurriculum(
            pool: pool, stats: [], targetCount: ScoringEngine.hmgsFullQuestionCount
        )
        XCTAssertEqual(selected.count, 120)
        XCTAssertEqual(Set(selected.map(\.id)).count, 120, "Tam denemede aynı soru iki kez çıkmamalı")
    }
}

/// KURTARMALI OKUMA TESTLERİ.
///
/// Gerçek kullanıcı geri bildirimi üzerine yazıldı: her aşama sonunda "Kayıtlı
/// ilerlemen okunamadı" uyarısı çıkıyor, uygulamayı kapatıp açmak da çözmüyordu.
/// Sebep: dosyadaki TEK bir okunamayan kayıt, dosyanın tamamını okunamaz yapıyordu.
/// Bu testler o davranışın geri gelmesini engelliyor.
final class LossyReadTests: XCTestCase {

    private var documents: URL {
        // Zorlama açma (!) kullanılmıyor — proje kuralı testlerde de geçerli.
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }

    private func write(_ json: String, to name: String) throws {
        try Data(json.utf8).write(to: documents.appendingPathComponent(name), options: .atomic)
    }

    private func remove(_ name: String) {
        try? FileManager.default.removeItem(at: documents.appendingPathComponent(name))
    }

    // MARK: - İstatistikler

    func testSingleUnreadableStatDoesNotKillTheWholeFile() throws {
        defer { remove("question_stats.json") }
        // İkinci kayıt bilerek bozuk: "subject" değeri bu sürümde yok.
        try write("""
        [
          {"questionID":"11111111-1111-4111-8111-111111111111","subject":"medeni_hukuk",
           "attempts":3,"correct":1,"wrong":2,"lastAttemptDate":"2026-01-15T10:00:00Z",
           "isInMistakePool":true},
          {"questionID":"22222222-2222-4222-8222-222222222222","subject":"artik_olmayan_ders",
           "attempts":1,"correct":1,"wrong":0,"lastAttemptDate":"2026-01-15T10:00:00Z",
           "isInMistakePool":false},
          {"questionID":"33333333-3333-4333-8333-333333333333","subject":"ceza_hukuku",
           "attempts":2,"correct":0,"wrong":2,"lastAttemptDate":"2026-01-16T10:00:00Z",
           "isInMistakePool":true}
        ]
        """, to: "question_stats.json")

        let stats = try LocalStore.loadStats()

        XCTAssertEqual(stats.count, 2, "Bozuk tek kayıt yüzünden diğer kayıtlar kaybolmamalı")
        XCTAssertTrue(stats.contains { $0.subject == .medeniHukuk })
        XCTAssertTrue(stats.contains { $0.subject == .cezaHukuku })
    }

    func testFileIsHealedSoTheSalvageHappensOnlyOnce() throws {
        defer { remove("question_stats.json") }
        try write("""
        [
          {"questionID":"11111111-1111-4111-8111-111111111111","subject":"medeni_hukuk",
           "attempts":1,"correct":1,"wrong":0,"lastAttemptDate":"2026-01-15T10:00:00Z",
           "isInMistakePool":false},
          {"bozuk":"kayıt"}
        ]
        """, to: "question_stats.json")

        _ = try LocalStore.loadStats()

        // İlk okumadan sonra dosya temiz hâliyle geri yazılmış olmalı: ikinci okuma
        // artık olağan yoldan (ayıklamasız) geçiyor.
        let data = try Data(contentsOf: documents.appendingPathComponent("question_stats.json"))
        let clean = try JSONDecoder.hmgs.decode([QuestionStat].self, from: data)
        XCTAssertEqual(clean.count, 1)
    }

    func testCleanFileIsNotRewritten() throws {
        defer { remove("question_stats.json") }
        let stat = QuestionStat(
            questionID: UUID(), subject: .borclarHukuku, attempts: 1, correct: 1, wrong: 0,
            lastAttemptDate: Date(timeIntervalSince1970: 1_700_000_000), isInMistakePool: false
        )
        try LocalStore.upsertStats([stat])
        let before = try Data(contentsOf: documents.appendingPathComponent("question_stats.json"))

        _ = try LocalStore.loadStats()

        let after = try Data(contentsOf: documents.appendingPathComponent("question_stats.json"))
        XCTAssertEqual(before, after, "Sağlam dosya boş yere yeniden yazılmamalı")
    }

    // MARK: - Oturumlar

    func testUnknownExamScopeDropsOnlyThatSession() throws {
        defer { remove("exam_sessions.json") }
        try write("""
        [
          {"id":"44444444-4444-4444-8444-444444444444",
           "scope":{"fullHMGS":{}},
           "startedAt":"2026-01-15T10:00:00Z","finishedAt":"2026-01-15T10:30:00Z",
           "answers":[],"timeMode":"untimed","measuredElapsedSeconds":1800},
          {"id":"55555555-5555-4555-8555-555555555555",
           "scope":{"gelecektekiYeniMod":{}},
           "startedAt":"2026-01-15T11:00:00Z","finishedAt":"2026-01-15T11:30:00Z",
           "answers":[],"timeMode":"untimed","measuredElapsedSeconds":1800}
        ]
        """, to: "exam_sessions.json")

        let sessions = try LocalStore.loadSessions()

        XCTAssertEqual(sessions.count, 1, "Tanınmayan kapsam yalnızca kendi oturumunu düşürmeli")
    }

    // MARK: - Hata şiddeti

    func testOnlyWriteFailuresAreShownToTheUser() {
        let dummy = NSError(domain: "test", code: 1)
        let write = LocalStore.StoreError.writeFailed(file: "x.json", underlying: dummy)
        let read = LocalStore.StoreError.readFailed(file: "x.json", underlying: dummy)

        // Yer açmak işe yarar → söyle.
        XCTAssertTrue(write.isUserActionable)
        // "Uygulamayı kapatıp aç" sorunu çözmüyor → kutlama ekranını bozma, günlüğe yaz.
        XCTAssertFalse(read.isUserActionable)
    }
}
