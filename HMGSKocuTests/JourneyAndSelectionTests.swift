import XCTest
@testable import HMGSKocu

/// Yolculuk aşama sisteminin en kritik sözü: **eski aşamalar asla değişmez.**
/// Bu bozulursa kullanıcının "3. aşamayı bitirdim" kaydı sessizce başka bir soru
/// kümesine işaret etmeye başlar — sessiz veri bozulması. Bu yüzden burası
/// projenin en çok testi olan yeri.
final class JourneyCatalogueTests: XCTestCase {

    func testStagesAreEightQuestionsEach() {
        let pool = TestFixtures.questions(count: 20, subject: .medeniHukuk)
        let layout = JourneyCatalogue.reconcile(layout: JourneyStageLayout(), pool: pool)
        let stages = layout.stagesBySubject[LegalSubject.medeniHukuk.rawValue] ?? []

        XCTAssertEqual(stages.count, 3, "20 soru = 8 + 8 + 4")
        XCTAssertEqual(stages[0].count, 8)
        XCTAssertEqual(stages[1].count, 8)
        XCTAssertEqual(stages[2].count, 4)
    }

    func testExistingStagesNeverChangeWhenContentIsAdded() {
        let original = TestFixtures.questions(count: 20, subject: .medeniHukuk)
        let first = JourneyCatalogue.reconcile(layout: JourneyStageLayout(), pool: original)

        // İçerik güncellemesi: 15 yeni soru geldi, üstelik hepsi "kolay"
        // (yani eski sıralamada başa gelirlerdi).
        let newcomers = TestFixtures.questions(count: 15, subject: .borclarHukuku)
            .map { question -> Question in
                var copy = question
                copy.subject = .medeniHukuk
                copy.difficulty = .kolay
                return copy
            }
        let second = JourneyCatalogue.reconcile(layout: first, pool: original + newcomers)

        let before = first.stagesBySubject[LegalSubject.medeniHukuk.rawValue] ?? []
        let after = second.stagesBySubject[LegalSubject.medeniHukuk.rawValue] ?? []

        XCTAssertGreaterThan(after.count, before.count, "Yeni sorular yeni aşama açmalı")
        // İlk iki dolu aşama harfi harfine aynı kalmalı.
        XCTAssertEqual(before[0], after[0])
        XCTAssertEqual(before[1], after[1])
        // Yarım kalan son aşama önce doldurulur, ama içindeki eski sorular yerinde kalır.
        XCTAssertEqual(Array(after[2].prefix(before[2].count)), before[2])
    }

    func testHalfFullLastStageIsToppedUpFirst() {
        let pool = TestFixtures.questions(count: 12, subject: .cezaHukuku)   // 8 + 4
        let first = JourneyCatalogue.reconcile(layout: JourneyStageLayout(), pool: pool)
        XCTAssertEqual(first.stagesBySubject[LegalSubject.cezaHukuku.rawValue]?.last?.count, 4)

        let extra = TestFixtures.questions(count: 3, subject: .cezaHukuku).map { question -> Question in
            var copy = question
            copy.topicTag = "Yeni"
            return copy
        }
        // Aynı ID'ler üretilmesin diye yeni ID'li sorular kuruyoruz.
        let renumbered = extra.enumerated().map { index, question -> Question in
            Question(
                id: UUID(),
                subject: question.subject,
                difficulty: question.difficulty,
                topicTag: "Yeni \(index)",
                prompt: question.prompt,
                options: question.options,
                correctOptionIndex: question.correctOptionIndex,
                explanation: question.explanation,
                lawReference: question.lawReference
            )
        }
        let second = JourneyCatalogue.reconcile(layout: first, pool: pool + renumbered)
        let stages = second.stagesBySubject[LegalSubject.cezaHukuku.rawValue] ?? []

        XCTAssertEqual(stages.count, 2, "3 yeni soru son aşamaya sığmalı, yeni aşama açılmamalı")
        XCTAssertEqual(stages.last?.count, 7)
    }

    func testReconcileIsIdempotent() {
        let pool = TestFixtures.questions(count: 25, subject: .ticaretHukuku)
        let once = JourneyCatalogue.reconcile(layout: JourneyStageLayout(), pool: pool)
        let twice = JourneyCatalogue.reconcile(layout: once, pool: pool)
        XCTAssertEqual(once, twice, "Aynı havuzla ikinci çağrı hiçbir şeyi değiştirmemeli")
    }

    func testRemovedQuestionsArePrunedButStageIndicesSurvive() {
        let pool = TestFixtures.questions(count: 16, subject: .isHukuku)
        let layout = JourneyCatalogue.reconcile(layout: JourneyStageLayout(), pool: pool)

        // İlk aşamanın tüm soruları içerikten kaldırıldı (örn. hatalı bulundukları için).
        let firstStageIDs = Set(layout.stagesBySubject[LegalSubject.isHukuku.rawValue]?[0] ?? [])
        let shrunkPool = pool.filter { !firstStageIDs.contains($0.id) }
        let after = JourneyCatalogue.reconcile(layout: layout, pool: shrunkPool)
        let stages = after.stagesBySubject[LegalSubject.isHukuku.rawValue] ?? []

        XCTAssertEqual(stages.count, 2, "Aşama sırası korunmalı; 2. aşama hâlâ 2. aşama olmalı")
        XCTAssertTrue(stages[0].isEmpty)
        XCTAssertEqual(stages[1].count, 8)

        // Boşalan aşama arayüzde gösterilmiyor ama indeksi kaymıyor.
        let visible = JourneyCatalogue.stages(for: .isHukuku, layout: after, pool: shrunkPool)
        XCTAssertEqual(visible.count, 1)
        XCTAssertEqual(visible.first?.index, 1)
    }

    func testStagesAreOrderedByDifficulty() {
        let easy = TestFixtures.questions(count: 4, subject: .vergiHukuku, difficulty: .kolay)
        let hard = TestFixtures.questions(count: 4, subject: .vergiHukuku, difficulty: .zor)
            .map { question -> Question in
                Question(id: UUID(), subject: .vergiHukuku, difficulty: .zor, topicTag: question.topicTag,
                         prompt: question.prompt, options: question.options,
                         correctOptionIndex: question.correctOptionIndex,
                         explanation: question.explanation, lawReference: question.lawReference)
            }
        let layout = JourneyCatalogue.reconcile(layout: JourneyStageLayout(), pool: hard + easy)
        let ids = layout.stagesBySubject[LegalSubject.vergiHukuku.rawValue]?.flatMap { $0 } ?? []
        let byID = Dictionary(uniqueKeysWithValues: (hard + easy).map { ($0.id, $0) })
        let difficulties = ids.compactMap { byID[$0]?.difficulty }

        XCTAssertEqual(difficulties.prefix(4), [.kolay, .kolay, .kolay, .kolay])
    }

    func testProgressUnlockRules() {
        let pool = TestFixtures.questions(count: 24, subject: .idareHukuku)
        let layout = JourneyCatalogue.reconcile(layout: JourneyStageLayout(), pool: pool)
        let stages = JourneyCatalogue.stages(for: .idareHukuku, layout: layout, pool: pool)
        var progress = JourneyProgress()

        XCTAssertTrue(progress.isUnlocked(stages[0]), "İlk aşama hep açık")
        XCTAssertFalse(progress.isUnlocked(stages[1]))

        progress.markCompleted(stages[0])
        XCTAssertTrue(progress.isUnlocked(stages[1]))
        XCTAssertFalse(progress.isUnlocked(stages[2]))
        XCTAssertEqual(progress.totalCompletedStageCount, 1)
    }
}

final class QuestionSelectorTests: XCTestCase {

    func testUnseenQuestionsComeFirst() {
        let pool = TestFixtures.questions(count: 10, subject: .medeniHukuk)
        // İlk 5'i daha önce doğru çözülmüş.
        let stats = pool.prefix(5).map { TestFixtures.stat(questionID: $0.id) }

        let ordered = QuestionSelector.prioritized(pool: pool, stats: Array(stats))
        let firstFive = Set(ordered.prefix(5).map(\.id))
        let unseen = Set(pool.suffix(5).map(\.id))

        XCTAssertEqual(firstFive, unseen, "Hiç görülmemiş sorular başa gelmeli")
    }

    func testMistakePoolQuestionsComeBeforeMastered() {
        let pool = TestFixtures.questions(count: 6, subject: .cezaHukuku)
        var stats: [QuestionStat] = []
        for (index, question) in pool.enumerated() {
            stats.append(TestFixtures.stat(questionID: question.id, subject: .cezaHukuku, inMistakePool: index < 3))
        }

        let ordered = QuestionSelector.prioritized(pool: pool, stats: stats)
        let mistakeIDs = Set(pool.prefix(3).map(\.id))
        XCTAssertEqual(Set(ordered.prefix(3).map(\.id)), mistakeIDs)
    }

    func testSelectorNeverLosesOrDuplicatesQuestions() {
        let pool = TestFixtures.questions(count: 30, subject: .borclarHukuku)
        let ordered = QuestionSelector.prioritized(pool: pool, stats: [])
        XCTAssertEqual(ordered.count, pool.count)
        XCTAssertEqual(Set(ordered.map(\.id)), Set(pool.map(\.id)))
    }

    func testWeightedCurriculumRespectsTargetCount() {
        var pool: [Question] = []
        for subject in LegalSubject.allCases {
            pool += TestFixtures.questions(count: 20, subject: subject).map { question in
                Question(id: UUID(), subject: subject, difficulty: .orta, topicTag: question.topicTag,
                         prompt: question.prompt, options: question.options,
                         correctOptionIndex: question.correctOptionIndex,
                         explanation: question.explanation, lawReference: question.lawReference)
            }
        }

        for target in [10, 20, 40, 120] {
            let selected = QuestionSelector.weightedFullCurriculum(pool: pool, stats: [], targetCount: target)
            XCTAssertEqual(selected.count, target, "\(target) soru istendi, \(selected.count) geldi")
            XCTAssertEqual(Set(selected.map(\.id)).count, selected.count, "Aynı soru iki kez gelmemeli")
        }
    }

    func testWeightedCurriculumFavoursHighWeightSubjects() {
        var pool: [Question] = []
        for subject in LegalSubject.allCases {
            pool += (0..<30).map { _ in
                Question(id: UUID(), subject: subject, difficulty: .orta, topicTag: "T",
                         prompt: "P", options: ["1", "2", "3", "4", "5"], correctOptionIndex: 0,
                         explanation: "E", lawReference: nil)
            }
        }
        let selected = QuestionSelector.weightedFullCurriculum(pool: pool, stats: [], targetCount: 120)
        let medeni = selected.filter { $0.subject == .medeniHukuk }.count
        let genelKamu = selected.filter { $0.subject == .genelKamuHukuku }.count

        // Gerçek sınavda Medeni 15/120, Genel Kamu 3/120.
        XCTAssertGreaterThan(medeni, genelKamu)
        XCTAssertGreaterThanOrEqual(medeni, 10)
    }

    func testWeightedCurriculumHandlesEmptyPool() {
        XCTAssertTrue(QuestionSelector.weightedFullCurriculum(pool: [], stats: [], targetCount: 20).isEmpty)
    }

    func testZeroTargetReturnsNothing() {
        let pool = TestFixtures.questions(count: 5)
        XCTAssertTrue(QuestionSelector.weightedFullCurriculum(pool: pool, stats: [], targetCount: 0).isEmpty)
    }
}
