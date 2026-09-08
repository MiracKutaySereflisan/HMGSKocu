import Foundation

/// Uygulamayla birlikte gelen soru havuzunu okur.
///
/// Bozuk ya da eksik bir soru YÜZÜNDEN uygulama çökmez: tek tek çözümlenip
/// geçersiz olanlar elenir. 680 sorudan biri bozuksa kullanıcı 679 soruyla çalışır,
/// "Sorular yüklenemedi" ekranı görmez.
enum SeedQuestionLoader {

    enum LoaderError: LocalizedError {
        case bundleResourceMissing
        case unreadable(Error)
        case emptyPool

        var errorDescription: String? {
            switch self {
            case .bundleResourceMissing:
                return "Soru dosyası uygulamaya eklenmemiş. (Geliştirici: seed_questions.json hedefin Copy Bundle Resources adımında olmalı.)"
            case .unreadable:
                return "Soru dosyası okunamadı."
            case .emptyPool:
                return "Soru havuzu boş görünüyor."
            }
        }
    }

    /// Havuzdaki tüm geçerli sorular.
    static func loadAll(bundle: Bundle = .main) throws -> [Question] {
        guard let url = bundle.url(forResource: "seed_questions", withExtension: "json") else {
            throw LoaderError.bundleResourceMissing
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LoaderError.unreadable(error)
        }
        return try decode(data)
    }

    /// Ham veriden çözümleme — testlerden doğrudan çağrılabilsin diye ayrı.
    static func decode(_ data: Data) throws -> [Question] {
        let decoder = JSONDecoder.hmgs
        let raw: [FailableQuestion]
        do {
            raw = try decoder.decode([FailableQuestion].self, from: data)
        } catch {
            throw LoaderError.unreadable(error)
        }

        var seen = Set<UUID>()
        var result: [Question] = []
        result.reserveCapacity(raw.count)
        for entry in raw {
            guard let question = entry.value, question.isWellFormed else { continue }
            guard seen.insert(question.id).inserted else { continue }   // aynı ID iki kez varsa ilkini al
            result.append(question)
        }

        guard !result.isEmpty else { throw LoaderError.emptyPool }
        return result
    }

    /// Tek bir sorunun çözümlemesi patlarsa tüm diziyi düşürmemek için sarmalayıcı.
    private struct FailableQuestion: Decodable {
        let value: Question?
        init(from decoder: Decoder) throws {
            value = try? Question(from: decoder)
        }
    }
}
