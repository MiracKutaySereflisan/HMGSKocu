// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import Foundation

/// Yolculuk modunun XP ve seviye kuralları. `ScoringEngine` HMGS puanlamasını nasıl
/// tek yerde topluyorsa bu da oyunlaştırmayı öyle topluyor. Saf/durumsuz —
/// kalıcılık ve yan etki yok.
enum XPEngine {
    static let xpPerCorrectAnswer = 10
    static let stageFirstClearBonus = 20
    static let stageRepeatBonus = 5
    static let stagePassThreshold = 0.7   // %70 doğru = aşama geçildi

    struct StageResult: Equatable {
        let xpEarned: Int
        let passed: Bool
        let wasFirstClear: Bool
        let correctCount: Int
        let totalCount: Int
    }

    /// Bir Yolculuk aşaması bittiğinde bir kez çağrılır.
    static func evaluate(session: ExamSession, wasAlreadyCompleted: Bool) -> StageResult {
        let correctXP = session.correctCount * xpPerCorrectAnswer
        let ratio = session.totalCount == 0 ? 0 : Double(session.correctCount) / Double(session.totalCount)
        let passed = session.totalCount > 0 && ratio >= stagePassThreshold
        let wasFirstClear = passed && !wasAlreadyCompleted
        // İlk geçişte gerçek bir bonus var; geçilmiş bir aşamayı tekrar çözmek yine
        // bir şey kazandırıyor (tekrar cezalandırılmasın) ama XP çiftliği olmasın
        // diye çok daha az.
        let bonus = passed ? (wasFirstClear ? stageFirstClearBonus : stageRepeatBonus) : 0
        return StageResult(
            xpEarned: correctXP + bonus,
            passed: passed,
            wasFirstClear: wasFirstClear,
            correctCount: session.correctCount,
            totalCount: session.totalCount
        )
    }

    /// `level` seviyesinden `level + 1`'e geçmek için gereken XP. Yumuşak bir rampa:
    /// ilk seviyeler hızlı gelir, sonrakiler biraz uzar; elle ayarlanan tablo yok.
    static func xpRequired(forLevel level: Int) -> Int {
        let safeLevel = max(1, level)
        return 50 + (safeLevel - 1) * 25
    }

    static func level(forTotalXP xp: Int) -> Int {
        progress(forTotalXP: xp).level
    }

    /// Mevcut seviye + o seviyenin içindeki ilerleme (rozet ve ilerleme çubuğu için).
    static func progress(forTotalXP xp: Int) -> (level: Int, xpIntoLevel: Int, xpForLevel: Int) {
        var remaining = max(0, xp)
        var level = 1
        // Üst sınır: bozuk/aşırı büyük bir XP değerinde sonsuz döngüye girmesin.
        while level < 10_000, remaining >= xpRequired(forLevel: level) {
            remaining -= xpRequired(forLevel: level)
            level += 1
        }
        return (level, remaining, xpRequired(forLevel: level))
    }
}
