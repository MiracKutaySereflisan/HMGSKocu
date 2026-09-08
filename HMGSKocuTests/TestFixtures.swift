import Foundation
@testable import HMGSKocu

/// Testlerde kullanılan sahte veri üreticileri. Gerçek kişi verisi ASLA
/// kullanılmıyor — hepsi uydurma metin.
enum TestFixtures {

    static func question(
        id: UUID = UUID(),
        subject: LegalSubject = .medeniHukuk,
        difficulty: Difficulty = .orta,
        topicTag: String = "Test Konusu",
        correctOptionIndex: Int = 0
    ) -> Question {
        Question(
            id: id,
            subject: subject,
            difficulty: difficulty,
            topicTag: topicTag,
            prompt: "Test sorusu \(id.uuidString.prefix(8))",
            options: ["A şıkkı", "B şıkkı", "C şıkkı", "D şıkkı", "E şıkkı"],
            correctOptionIndex: correctOptionIndex,
            explanation: "Test açıklaması.",
            lawReference: "TMK m. 1",
            isVerifiedPastExamQuestion: false,
            examYear: nil
        )
    }

    static func questions(count: Int, subject: LegalSubject = .medeniHukuk, difficulty: Difficulty = .orta) -> [Question] {
        (0..<count).map { index in
            question(
                id: deterministicUUID(subject: subject, index: index),
                subject: subject,
                difficulty: difficulty,
                topicTag: "Konu \(index)"
            )
        }
    }

    /// Testler tekrarlanabilir olsun diye sabit UUID üretimi.
    static func deterministicUUID(subject: LegalSubject, index: Int) -> UUID {
        let hex = String(format: "%08x", abs(subject.rawValue.hashValue % 0xFFFF_FFFF))
        let tail = String(format: "%012x", index)
        return UUID(uuidString: "\(hex.prefix(8))-0000-4000-8000-\(tail.suffix(12))")
            ?? UUID()
    }

    static func session(
        correct: Int,
        wrong: Int,
        blank: Int,
        scope: ExamScope = .fullHMGS,
        timeMode: TimeMode = .untimed,
        elapsed: Double = 60
    ) -> ExamSession {
        var answers: [AnswerRecord] = []
        for _ in 0..<correct {
            answers.append(AnswerRecord(questionID: UUID(), selectedOptionIndex: 0, isCorrect: true, timeSpentSeconds: 5))
        }
        for _ in 0..<wrong {
            answers.append(AnswerRecord(questionID: UUID(), selectedOptionIndex: 1, isCorrect: false, timeSpentSeconds: 5))
        }
        for _ in 0..<blank {
            answers.append(AnswerRecord(questionID: UUID(), selectedOptionIndex: nil, isCorrect: nil, timeSpentSeconds: 2))
        }
        let started = Date().addingTimeInterval(-elapsed)
        return ExamSession(
            id: UUID(),
            scope: scope,
            startedAt: started,
            finishedAt: Date(),
            answers: answers,
            timeMode: timeMode,
            timeLimitSeconds: timeMode == .hmgsStandard ? 600 : nil,
            measuredElapsedSeconds: elapsed
        )
    }

    static func stat(
        questionID: UUID,
        subject: LegalSubject = .medeniHukuk,
        inMistakePool: Bool = false,
        wasBlank: Bool = false,
        lastAttempt: Date = Date()
    ) -> QuestionStat {
        QuestionStat(
            questionID: questionID,
            subject: subject,
            attempts: 1,
            correct: inMistakePool ? 0 : 1,
            wrong: inMistakePool && !wasBlank ? 1 : 0,
            blank: wasBlank ? 1 : 0,
            lastAttemptDate: lastAttempt,
            isInMistakePool: inMistakePool,
            wasLastAttemptBlank: wasBlank,
            reclaimedCount: 0
        )
    }
}
