// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import Foundation

/// Yolculuk yolundaki tek bir "ders" düğümü — bir dersin mevcut soru havuzundan
/// alınmış, zorluğu artan sırada dizilmiş sabit bir dilim. Aşamalar türetilir,
/// elle yazılmaz: bu modu yayınlamak için yeni içerik gerekmiyor.
struct Stage: Identifiable, Hashable, Sendable {
    let subject: LegalSubject
    let index: Int                 // ders içindeki 0 tabanlı sıra
    let questionIDs: [UUID]
    let dominantTopicTag: String   // düğümün alt başlığı için en temsili konu etiketi

    var id: String { "\(subject.rawValue)_\(index)" }
    var title: String { "\(index + 1). Aşama" }
}

/// Diske yazılan aşama yerleşimi: hangi soru hangi aşamada. Asıl kaydedilen şey bu;
/// `Stage` nesneleri bunun üzerinde salt okunur bir görünüm.
///
/// Neden her açılışta havuzdan yeniden hesaplanmıyor: sıralama içerik güncellemeleri
/// arasında kararlı değil. `seed_questions.json`'a yeni soru eklendiğinde aşamalar
/// baştan hesaplansaydı bir dersin aşama sınırları kayardı — 9. soru 2. aşamadan
/// 1. aşamaya geçebilirdi — ve kullanıcının "3. aşamayı bitirdim" kaydı sessizce
/// başka bir soru kümesini işaret etmeye başlardı. Yerleşimi kaydedip yalnızca
/// SONUNA eklemek (bkz. `JourneyCatalogue.reconcile`) aşama kimliğini kalıcı yapar.
struct JourneyStageLayout: Codable, Equatable, Sendable {
    var stagesBySubject: [String: [[UUID]]] = [:]   // LegalSubject.rawValue -> sıralı aşamalar
}

/// Her ders için Yolculuk yolunu mevcut yerel soru havuzundan kurar ve büyütür.
enum JourneyCatalogue {
    static let questionsPerStage = 8

    /// Kayıtlı (boş ya da eski olabilir) yerleşimi güncel soru havuzuyla uyumlu hale
    /// getirir:
    /// - Daha önce yerleştirilmiş her aşama **aynen** korunur.
    /// - Hiçbir aşamada olmayan sorular önce son aşamanın boşluğunu doldurur,
    ///   sonra yeni aşamalar olarak sona eklenir.
    /// - Yeni sorular yalnızca kendi aralarında zorluğa göre sıralanır.
    /// - Havuzdan KALDIRILMIŞ sorular (artık `pool` içinde olmayan ID'ler) aşamadan
    ///   temizlenir; aşama tamamen boşalsa bile aşama sırası korunur, böylece
    ///   "5. aşamayı geçtim" kaydı hâlâ 5. aşamayı işaret eder.
    ///
    /// Her yüklemede bir kez çağrılır; yeni bir şey yoksa hiçbir şeyi değiştirmez.
    static func reconcile(layout: JourneyStageLayout, pool: [Question]) -> JourneyStageLayout {
        var updated = layout
        let poolIDs = Set(pool.map(\.id))

        for subject in LegalSubject.allCases {
            let subjectQuestions = pool.filter { $0.subject == subject }

            var stages = updated.stagesBySubject[subject.rawValue] ?? []
            // Havuzdan kaldırılmış soruları aşamalardan düş (aşama sayısı sabit kalır).
            var didPrune = false
            for i in stages.indices {
                let cleaned = stages[i].filter { poolIDs.contains($0) }
                if cleaned.count != stages[i].count {
                    stages[i] = cleaned
                    didPrune = true
                }
            }

            guard !subjectQuestions.isEmpty else {
                if didPrune { updated.stagesBySubject[subject.rawValue] = stages }
                continue
            }

            let alreadyPlaced = Set(stages.flatMap { $0 })
            var newcomers = subjectQuestions
                .filter { !alreadyPlaced.contains($0.id) }
                .sorted { lhs, rhs in
                    if lhs.difficulty.sortOrder != rhs.difficulty.sortOrder {
                        return lhs.difficulty.sortOrder < rhs.difficulty.sortOrder
                    }
                    if lhs.topicTag != rhs.topicTag { return lhs.topicTag < rhs.topicTag }
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                .map(\.id)

            guard !newcomers.isEmpty else {
                if didPrune { updated.stagesBySubject[subject.rawValue] = stages }
                continue
            }

            if let lastIndex = stages.indices.last, stages[lastIndex].count < questionsPerStage {
                let room = questionsPerStage - stages[lastIndex].count
                let take = min(room, newcomers.count)
                stages[lastIndex].append(contentsOf: newcomers.prefix(take))
                newcomers.removeFirst(take)
            }
            for start in stride(from: 0, to: newcomers.count, by: questionsPerStage) {
                let end = min(start + questionsPerStage, newcomers.count)
                stages.append(Array(newcomers[start..<end]))
            }
            updated.stagesBySubject[subject.rawValue] = stages
        }

        return updated
    }

    /// Bir dersin yerleşim diliminin arayüz için salt okunur `Stage` görünümü.
    /// İçi boşalmış aşamalar (tüm soruları havuzdan kaldırılmış) gösterilmez ama
    /// indeksleri korunur.
    static func stages(for subject: LegalSubject, layout: JourneyStageLayout, pool: [Question]) -> [Stage] {
        let subjectQuestions = pool.filter { $0.subject == subject }
        var questionsByID: [UUID: Question] = [:]
        for question in subjectQuestions { questionsByID[question.id] = question }

        let stageIDLists = layout.stagesBySubject[subject.rawValue] ?? []
        return stageIDLists.enumerated().compactMap { index, ids in
            guard !ids.isEmpty else { return nil }
            let tag = ids.compactMap { questionsByID[$0]?.topicTag }
                .first { !$0.isEmpty } ?? subject.displayName
            return Stage(subject: subject, index: index, questionIDs: ids, dominantTopicTag: tag)
        }
    }
}

/// Diske yazılan Yolculuk ilerlemesi: ders bazında geçilen aşamalar + toplam XP.
/// Seviye bilinçli olarak saklanmıyor — her zaman `totalXP`'den `XPEngine` ile
/// türetiliyor ki birbirinden kayabilecek iki sayı olmasın.
struct JourneyProgress: Codable, Equatable, Sendable {
    var completedStageIndices: [String: Set<Int>] = [:]
    var totalXP: Int = 0

    func isCompleted(_ stage: Stage) -> Bool {
        completedStageIndices[stage.subject.rawValue]?.contains(stage.index) ?? false
    }

    /// Bir aşama, kendinden önceki tüm aşamalar geçilince açılır.
    func isUnlocked(_ stage: Stage) -> Bool {
        stage.index == 0 || completedStageIndices[stage.subject.rawValue]?.contains(stage.index - 1) == true
    }

    mutating func markCompleted(_ stage: Stage) {
        completedStageIndices[stage.subject.rawValue, default: []].insert(stage.index)
    }

    var totalCompletedStageCount: Int {
        completedStageIndices.values.reduce(0) { $0 + $1.count }
    }
}
