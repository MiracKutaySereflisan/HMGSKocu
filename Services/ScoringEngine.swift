// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import Foundation

/// Gerçek HMGS kurallarının tek yerde toplandığı motor:
/// - 120 soru / 155 dakika (soru başına ≈77,5 sn) — bkz. `Question.secondsPerQuestion`
/// - Yanlış doğruyu götürmez, sadece doğrular puanlanır
/// - Başarı barajı: 100 üzerinden 70 (120 soruda en az 84 doğru)
enum ScoringEngine {
    static let hmgsFullQuestionCount = 120
    static let hmgsFullTimeMinutes = 155
    static let hmgsPassThresholdOutOf100 = 70.0
    static let hmgsMinCorrectForFull = 84

    struct Result: Equatable {
        let correct: Int
        let wrong: Int
        let blank: Int
        let scoreOutOf100: Double
        let passed: Bool
    }

    static func score(_ session: ExamSession) -> Result {
        Result(
            correct: session.correctCount,
            wrong: session.wrongCount,
            blank: session.blankCount,
            scoreOutOf100: session.scoreOutOf100,
            passed: session.scoreOutOf100 >= hmgsPassThresholdOutOf100
        )
    }
}

/// Her bitmiş sınavdan sonra sabit `AchievementCatalogue`'u mevcut duruma karşı
/// değerlendirir. Saf fonksiyon — kalıcılık ya da yan etki yok, bu yüzden test edilebilir.
enum AchievementEngine {

    struct Input {
        let finishedSession: ExamSession
        let allSessions: [ExamSession]
        let subjectProgress: [SubjectProgress]
        /// Hata havuzunda şu an kaç soru duruyor
        let mistakePoolRemaining: Int
        /// Hayat boyu havuza en az bir kez düşmüş soru sayısı — "Havuzu Boşalttın"
        /// başarımının, hiç hata yapmamış birine yanlışlıkla verilmemesi için gerekli.
        let everInMistakePoolCount: Int
        let journeyCompletedStageCount: Int
        let currentStreak: Int
        let alreadyUnlocked: Set<String>
    }

    static func evaluate(_ input: Input) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []
        var unlockedIDs = input.alreadyUnlocked

        func unlock(_ id: String) {
            guard !unlockedIDs.contains(id), var template = AchievementCatalogue.template(id: id) else { return }
            template.unlockedAt = Date()
            unlockedIDs.insert(id)
            newlyUnlocked.append(template)
        }

        // "İlk Adım": eski kod `allSessions.count == 1` diye bakıyordu; kayıt bir kez
        // başarısız olursa başarım sonsuza dek kilitli kalıyordu. Artık en az bir
        // oturum varsa açılıyor.
        if !input.allSessions.isEmpty { unlock("ilk_sinav") }

        if input.finishedSession.scope.comparesToHMGSThreshold, input.finishedSession.passesHMGSThreshold {
            unlock("baraj_gecti")
        }

        if let medeni = input.subjectProgress.first(where: { $0.subject == .medeniHukuk }),
           medeni.solved >= 20, medeni.accuracy >= 0.9 {
            unlock("medeni_hukuk_ustasi")
        }

        // Havuz gerçekten dolup boşaldıysa anlamlı. Hiç yanlış yapmamış birinin
        // ilk sınavında bu başarımı alması hem yanlış hem de değersizleştirici.
        if input.mistakePoolRemaining == 0, input.everInMistakePoolCount > 0 {
            unlock("havuz_temiz")
        }

        let totalSolved = input.subjectProgress.reduce(0) { $0 + $1.solved }
        if totalSolved >= 100 { unlock("yuz_soru") }
        if totalSolved >= 1000 { unlock("bin_soru") }

        if input.finishedSession.timeMode == .hmgsStandard,
           input.finishedSession.scope.comparesToHMGSThreshold,
           let limit = input.finishedSession.timeLimitSeconds,
           input.finishedSession.elapsedSeconds < Double(limit) {
            unlock("zamanla_yaris")
        }

        if input.currentStreak >= 7 { unlock("yedi_gun") }
        if input.journeyCompletedStageCount >= 1 { unlock("ilk_asama") }
        if input.journeyCompletedStageCount >= 10 { unlock("on_asama") }

        return newlyUnlocked
    }
}
