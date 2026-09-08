import XCTest
@testable import HMGSKocu

/// Puanlama, XP ve başarım kuralları — uygulamanın "para eden" iş mantığı burada.
/// Bu testler ekran açmadan, cihaz gerektirmeden saniyeler içinde çalışır.
final class ScoringEngineTests: XCTestCase {

    func testScoreCountsOnlyCorrectAnswers() {
        // HMGS kuralı: yanlış doğruyu götürmez.
        let session = TestFixtures.session(correct: 7, wrong: 2, blank: 1)
        let result = ScoringEngine.score(session)

        XCTAssertEqual(result.correct, 7)
        XCTAssertEqual(result.wrong, 2)
        XCTAssertEqual(result.blank, 1)
        XCTAssertEqual(result.scoreOutOf100, 70.0, accuracy: 0.001)
        XCTAssertTrue(result.passed, "70 puan barajın tam üstü — geçmiş sayılmalı")
    }

    func testJustBelowThresholdFails() {
        let session = TestFixtures.session(correct: 69, wrong: 31, blank: 0)
        XCTAssertFalse(ScoringEngine.score(session).passed)
    }

    func testEmptySessionDoesNotDivideByZero() {
        let session = TestFixtures.session(correct: 0, wrong: 0, blank: 0)
        XCTAssertEqual(session.scoreOutOf100, 0)
        XCTAssertFalse(session.passesHMGSThreshold)
    }

    func testRealHMGSPaceMatchesOfficialRatio() {
        // 120 soru / 155 dakika
        let configuration = ExamConfiguration(scope: .fullHMGS, questionCount: 120, timeMode: .hmgsStandard)
        XCTAssertEqual(configuration.timeLimitSeconds, 155 * 60)
    }

    func testOfficialWeightsSumTo120() {
        XCTAssertEqual(LegalSubject.officialExamTotal, 120)
    }
}

final class XPEngineTests: XCTestCase {

    func testLevelCurveIsMonotonic() {
        var previous = 0
        for level in 1...50 {
            let required = XPEngine.xpRequired(forLevel: level)
            XCTAssertGreaterThan(required, previous)
            previous = required
        }
    }

    func testProgressMatchesAccumulatedRequirements() {
        // 1. seviyeden 2'ye 50, 2'den 3'e 75 XP gerekiyor.
        XCTAssertEqual(XPEngine.level(forTotalXP: 0), 1)
        XCTAssertEqual(XPEngine.level(forTotalXP: 49), 1)
        XCTAssertEqual(XPEngine.level(forTotalXP: 50), 2)
        XCTAssertEqual(XPEngine.level(forTotalXP: 124), 2)
        XCTAssertEqual(XPEngine.level(forTotalXP: 125), 3)
    }

    func testNegativeAndHugeXPDoNotCrash() {
        XCTAssertEqual(XPEngine.level(forTotalXP: -500), 1)
        XCTAssertGreaterThan(XPEngine.level(forTotalXP: 5_000_000), 1)
    }

    func testFirstClearPaysMoreThanRepeat() {
        let session = TestFixtures.session(correct: 8, wrong: 0, blank: 0, scope: .journeyStage(subject: .medeniHukuk, stageIndex: 0))

        let first = XPEngine.evaluate(session: session, wasAlreadyCompleted: false)
        let repeated = XPEngine.evaluate(session: session, wasAlreadyCompleted: true)

        XCTAssertTrue(first.passed)
        XCTAssertTrue(first.wasFirstClear)
        XCTAssertEqual(first.xpEarned, 8 * 10 + 20)
        XCTAssertEqual(repeated.xpEarned, 8 * 10 + 5)
        XCTAssertFalse(repeated.wasFirstClear)
    }

    func testBelowSeventyPercentDoesNotPass() {
        // 5/8 = %62,5 → geçemez, bonus da yok
        let session = TestFixtures.session(correct: 5, wrong: 3, blank: 0, scope: .journeyStage(subject: .medeniHukuk, stageIndex: 0))
        let result = XPEngine.evaluate(session: session, wasAlreadyCompleted: false)
        XCTAssertFalse(result.passed)
        XCTAssertEqual(result.xpEarned, 50, "Geçemese bile doğru başına XP verilmeli")
    }

    func testExactlySeventyPercentPasses() {
        // 7/10 = %70 — sınırın tam üstü
        let session = TestFixtures.session(correct: 7, wrong: 3, blank: 0, scope: .journeyStage(subject: .medeniHukuk, stageIndex: 0))
        XCTAssertTrue(XPEngine.evaluate(session: session, wasAlreadyCompleted: false).passed)
    }
}

final class AchievementEngineTests: XCTestCase {

    private func input(
        session: ExamSession,
        allSessions: [ExamSession]? = nil,
        subjectProgress: [SubjectProgress] = [],
        mistakePoolRemaining: Int = 0,
        everInMistakePoolCount: Int = 0,
        journeyCompletedStageCount: Int = 0,
        currentStreak: Int = 0,
        alreadyUnlocked: Set<String> = []
    ) -> AchievementEngine.Input {
        AchievementEngine.Input(
            finishedSession: session,
            allSessions: allSessions ?? [session],
            subjectProgress: subjectProgress,
            mistakePoolRemaining: mistakePoolRemaining,
            everInMistakePoolCount: everInMistakePoolCount,
            journeyCompletedStageCount: journeyCompletedStageCount,
            currentStreak: currentStreak,
            alreadyUnlocked: alreadyUnlocked
        )
    }

    func testFirstExamUnlocksFirstStep() {
        let session = TestFixtures.session(correct: 1, wrong: 0, blank: 0)
        let unlocked = AchievementEngine.evaluate(input(session: session)).map(\.id)
        XCTAssertTrue(unlocked.contains("ilk_sinav"))
    }

    /// Bu, eski koddaki gerçek bir hatanın regresyon testi: hiç yanlış yapmamış
    /// birine "Havuzu Boşalttın" başarımı veriliyordu.
    func testEmptyPoolAchievementRequiresHavingMadeMistakes() {
        let session = TestFixtures.session(correct: 10, wrong: 0, blank: 0)

        let withoutHistory = AchievementEngine.evaluate(
            input(session: session, mistakePoolRemaining: 0, everInMistakePoolCount: 0)
        ).map(\.id)
        XCTAssertFalse(withoutHistory.contains("havuz_temiz"))

        let withHistory = AchievementEngine.evaluate(
            input(session: session, mistakePoolRemaining: 0, everInMistakePoolCount: 12)
        ).map(\.id)
        XCTAssertTrue(withHistory.contains("havuz_temiz"))
    }

    func testAlreadyUnlockedAchievementsAreNotReturnedAgain() {
        let session = TestFixtures.session(correct: 1, wrong: 0, blank: 0)
        let unlocked = AchievementEngine.evaluate(
            input(session: session, alreadyUnlocked: ["ilk_sinav"])
        ).map(\.id)
        XCTAssertFalse(unlocked.contains("ilk_sinav"))
    }

    func testThresholdAchievementOnlyForFullExam() {
        let subjectExam = TestFixtures.session(correct: 10, wrong: 0, blank: 0, scope: .singleSubject(.medeniHukuk))
        XCTAssertFalse(AchievementEngine.evaluate(input(session: subjectExam)).map(\.id).contains("baraj_gecti"))

        let fullExam = TestFixtures.session(correct: 10, wrong: 0, blank: 0, scope: .fullHMGS)
        XCTAssertTrue(AchievementEngine.evaluate(input(session: fullExam)).map(\.id).contains("baraj_gecti"))
    }

    func testStreakAchievement() {
        let session = TestFixtures.session(correct: 1, wrong: 0, blank: 0)
        XCTAssertFalse(AchievementEngine.evaluate(input(session: session, currentStreak: 6)).map(\.id).contains("yedi_gun"))
        XCTAssertTrue(AchievementEngine.evaluate(input(session: session, currentStreak: 7)).map(\.id).contains("yedi_gun"))
    }

    func testCatalogueIDsAreUnique() {
        let ids = AchievementCatalogue.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Aynı id iki başarımda kullanılamaz")
    }
}

final class StreakCalculatorTests: XCTestCase {

    private func stamps(daysAgo: [Int], from reference: Date) -> [String] {
        let calendar = Calendar(identifier: .gregorian)
        return daysAgo.compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: reference)
                .map(StreakCalculator.formatter.string(from:))
        }
    }

    func testNoStampsMeansNoStreak() {
        XCTAssertEqual(StreakCalculator.streak(from: [], today: Date()), 0)
    }

    func testConsecutiveDaysEndingToday() {
        let today = Date()
        let list = stamps(daysAgo: [0, 1, 2], from: today)
        XCTAssertEqual(StreakCalculator.streak(from: list, today: today), 3)
    }

    /// Bugün henüz çözmediyse ama dün çözdüyse seri devam ediyor sayılır —
    /// kullanıcı günü henüz bitirmedi, sabah uygulamayı açınca "serin bitti"
    /// demek haksızlık olur.
    func testStreakSurvivesUntilEndOfToday() {
        let today = Date()
        let list = stamps(daysAgo: [1, 2], from: today)
        XCTAssertEqual(StreakCalculator.streak(from: list, today: today), 2)
    }

    func testGapBreaksStreak() {
        let today = Date()
        let list = stamps(daysAgo: [0, 1, 3, 4], from: today)
        XCTAssertEqual(StreakCalculator.streak(from: list, today: today), 2)
    }

    func testTwoDayGapMeansZero() {
        let today = Date()
        let list = stamps(daysAgo: [2, 3, 4], from: today)
        XCTAssertEqual(StreakCalculator.streak(from: list, today: today), 0)
    }
}

final class TimerFormattingTests: XCTestCase {

    func testUnderOneHour() {
        XCTAssertEqual(TimerEngine.format(seconds: 0), "00:00")
        XCTAssertEqual(TimerEngine.format(seconds: 65), "01:05")
        XCTAssertEqual(TimerEngine.format(seconds: 3599), "59:59")
    }

    /// Eski kod 155 dakikalık tam denemede "155:00" yazıyordu — saat gösterimi yok sayılmıştı.
    func testOverOneHourShowsHours() {
        XCTAssertEqual(TimerEngine.format(seconds: 3600), "1:00:00")
        XCTAssertEqual(TimerEngine.format(seconds: 155 * 60), "2:35:00")
    }

    func testNegativeIsClamped() {
        XCTAssertEqual(TimerEngine.format(seconds: -10), "00:00")
    }

    func testAccessibilityTextIsReadable() {
        XCTAssertEqual(TimerEngine.accessibilityText(seconds: 95, isCountdown: true), "Kalan süre: 1 dakika 35 saniye")
        XCTAssertEqual(TimerEngine.accessibilityText(seconds: 0, isCountdown: false), "Geçen süre: 0 saniye")
    }
}

final class FormattingTests: XCTestCase {

    func testPercentRounding() {
        XCTAssertEqual(Format.percent(0), "%0")
        XCTAssertEqual(Format.percent(0.666), "%67")
        XCTAssertEqual(Format.percent(1), "%100")
        XCTAssertEqual(Format.percent(1.5), "%100", "Sınır dışı değer kırpılmalı")
        XCTAssertEqual(Format.percent(-0.2), "%0")
    }

    /// Türkçe'de "i" harfinin büyüğü "İ"dir. `uppercased()` bunu bilmez ve
    /// bölüm başlıkları "İÇERİK" yerine "ICERIK" görünürdü.
    func testTurkishUppercasing() {
        XCTAssertEqual("içerik".uppercased(with: Locale.turkish), "İÇERİK")
        XCTAssertEqual("sınav".uppercased(with: Locale.turkish), "SINAV")
    }

    func testOptionLetterIsSafeOutOfRange() {
        XCTAssertEqual(Question.optionLetter(0), "A")
        XCTAssertEqual(Question.optionLetter(4), "E")
        XCTAssertEqual(Question.optionLetter(9), "?", "Sınır dışı indekste çökmemeli")
        XCTAssertEqual(Question.optionLetter(-1), "?")
    }
}
