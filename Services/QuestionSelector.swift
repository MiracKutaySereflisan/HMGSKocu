// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import Foundation

/// Bir çalışma oturumunda soruların hangi sırayla geleceğine karar verir.
///
/// Öncelik: (1) hiç görülmemiş sorular, (2) şu an hata havuzunda olanlar,
/// (3) daha önce doğru yapılmış olanlar — ve bunların içinde en uzun süredir
/// görülmeyen önce. Böylece tekrar tekrar aynı çözülmüş soruları görüp "yerimde
/// sayıyorum" hissi oluşmuyor.
///
/// Çözülmüş soruları tamamen DIŞLAMIYOR: küçük bir havuzda bazı derslerde yeterli
/// taze soru olmayabilir; oturumu eksik başlatmak yerine boşluğu bunlarla dolduruyor.
enum QuestionSelector {

    static func prioritized(pool: [Question], stats: [QuestionStat]) -> [Question] {
        var statByID: [UUID: QuestionStat] = [:]
        for stat in stats { statByID[stat.questionID] = stat }

        var unseen: [Question] = []
        var needsWork: [Question] = []
        var mastered: [(question: Question, lastAttempt: Date)] = []

        for question in pool {
            guard let stat = statByID[question.id] else {
                unseen.append(question)
                continue
            }
            if stat.isInMistakePool {
                needsWork.append(question)
            } else {
                mastered.append((question, stat.lastAttemptDate))
            }
        }

        unseen.shuffle()
        needsWork.shuffle()
        let masteredOrdered = mastered.sorted { $0.lastAttempt < $1.lastAttempt }.map(\.question)

        return unseen + needsWork + masteredOrdered
    }

    /// "Tüm HMGS Müfredatı" denemesi için gerçek 120 soruluk HMGS dağılımını
    /// (Medeni 15/120, Ceza 9/120, Genel Kamu 3/120 …) `targetCount`'a ölçekleyerek
    /// havuz kurar. Tüm soruları tek torbaya atıp rastgele çekmek, hangi dersin
    /// havuzda çok sorusu varsa onu şişirirdi.
    ///
    /// Resmî 20 dersin dışındakiler (ağırlık 0) yalnızca hedef sayı dolmazsa
    /// tamamlayıcı olarak kullanılır.
    static func weightedFullCurriculum(pool: [Question], stats: [QuestionStat], targetCount: Int) -> [Question] {
        guard targetCount > 0 else { return [] }
        let totalWeight = LegalSubject.officialExamTotal
        guard totalWeight > 0 else { return Array(prioritized(pool: pool, stats: stats).prefix(targetCount)) }

        let bySubject = Dictionary(grouping: pool, by: \.subject)
        var selected: [Question] = []
        var leftovers: [Question] = []

        // Ağırlığı yüksek dersten başlayarak dağıt: yuvarlama kaybı olursa
        // sınavda en çok soru çıkan dersten değil, en az çıkandan eksilsin.
        let weightedSubjects = LegalSubject.displayOrdered.filter { $0.isOfficialHMGSSubject }
        for subject in weightedSubjects {
            guard let subjectPool = bySubject[subject], !subjectPool.isEmpty else { continue }
            let ordered = prioritized(pool: subjectPool, stats: stats)
            let exact = Double(subject.officialWeight) / Double(totalWeight) * Double(targetCount)
            // En az 1: 20 soruluk bir denemede bile her dersten en az bir soru gelsin.
            let target = max(1, Int(exact.rounded()))
            selected += ordered.prefix(target)
            leftovers += ordered.dropFirst(target)
        }
        for subject in LegalSubject.allCases where !subject.isOfficialHMGSSubject {
            guard let subjectPool = bySubject[subject], !subjectPool.isEmpty else { continue }
            leftovers += prioritized(pool: subjectPool, stats: stats)
        }

        if selected.count > targetCount {
            // Fazlalığı, sınavdaki ağırlığı en düşük olan derslerden kırp.
            selected.shuffle()
            selected.sort { $0.subject.officialWeight > $1.subject.officialWeight }
            selected = Array(selected.prefix(targetCount))
        } else if selected.count < targetCount {
            leftovers.shuffle()
            selected += leftovers.prefix(targetCount - selected.count)
        }

        // Son karıştırma: dersler enum sırasına göre blok blok gelmesin.
        selected.shuffle()
        return selected
    }
}
