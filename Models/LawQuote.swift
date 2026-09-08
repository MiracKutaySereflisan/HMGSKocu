import Foundation

/// Açılış ekranında gösterilen hukuk/adalet temalı özlü sözler.
///
/// Kaynak notu: Bu sözler kamuya mal olmuş, yaygın olarak aktarılan özdeyişlerdir.
/// Bazı atıflar (özellikle antik dönem ve Latin özdeyişleri) kesin kaynağı tartışmalı
/// olabilir; bu yüzden hiçbiri birebir alıntı iddiasıyla, tırnak içinde bir kişiye
/// özel telifli metin olarak sunulmuyor. Telif korumalı bir esere ait metin
/// (şarkı sözü, kitap pasajı, yaşayan bir yazarın özgün cümlesi) bu listeye
/// EKLENMEZ — bkz. Docs/LICENSES.md.
struct LawQuote: Identifiable, Hashable, Sendable {
    let id: Int
    let text: String
    let author: String

    static let all: [LawQuote] = {
        let raw: [(String, String)] = [
            ("Adalet, herkese kendi hakkını vermeye yönelik sürekli ve değişmez istektir.", "Ulpianus"),
            ("Halkın esenliği, en yüce yasa olmalıdır.", "Cicero"),
            ("Adalet olmayan yerde erdem de yoktur.", "Montesquieu"),
            ("Yasalar, en kötü durumdaki insanı da gözeterek yapılmalıdır.", "Montesquieu"),
            ("Suç ile ceza arasında bir orantı bulunmalıdır.", "Cesare Beccaria"),
            ("Adaletsiz kuvvet zorbalıktır; kuvvetsiz adalet ise âcizdir.", "Blaise Pascal"),
            ("Adalet, erdemlerin en yücesidir.", "Aristoteles"),
            ("Kanunlara uymak, adaletin ilk şartıdır.", "Sokrates"),
            ("Adalet mülkün temelidir.", "Türk adliye geleneği özdeyişi"),
            ("Güçlü, zayıfı ezmesin diye bu kanunları koydum.", "Hammurabi Kanunları girişi"),
            ("Aşırı derecede adaletsiz olan hukuk, hukuk değildir.", "Gustav Radbruch"),
            ("Güç hakkı oluşturmaz; insan yalnızca meşru olana itaatle yükümlüdür.", "Jean-Jacques Rousseau"),
            ("Güçler ayrılığı olmayan yerde özgürlük de olamaz.", "Montesquieu"),
            ("Kanun serttir, ama kanundur.", "Latin hukuk özdeyişi — Dura lex, sed lex"),
            ("Hukukun olmadığı yerde özgürlük de yoktur.", "John Locke"),
            ("Herhangi bir yerdeki adaletsizlik, her yerdeki adalet için bir tehdittir.", "Martin Luther King Jr."),
            ("On suçlunun cezasız kalması, bir masumun haksız yere cezalandırılmasından iyidir.", "William Blackstone"),
            ("Kimse kendi davasında hâkim olamaz.", "Latin hukuk özdeyişi — Nemo iudex in causa sua"),
            ("Kanunsuz suç ve ceza olmaz.", "Latin hukuk özdeyişi — Nullum crimen sine lege"),
            ("Sözleşmelere uyulmalıdır.", "Latin hukuk özdeyişi — Pacta sunt servanda"),
            ("İddia eden ispatla yükümlüdür.", "Latin hukuk özdeyişi — Ei incumbit probatio qui dicit"),
            ("Şüpheden sanık yararlanır.", "Ceza hukuku ilkesi — In dubio pro reo"),
            ("Düşünmeden öğrenmek boşa emektir; öğrenmeden düşünmek ise tehlikelidir.", "Konfüçyüs"),
            ("Bugün yaptığın küçük tekrar, sınav günü hatırladığın tek şey olabilir.", "HMGS Koçu"),
        ]
        return raw.enumerated().map { LawQuote(id: $0.offset, text: $0.element.0, author: $0.element.1) }
    }()

    /// Rastgele bir söz. Liste boş olamaz ama `randomElement()!` yerine güvenli
    /// bir düşüş yolu kullanılıyor — kod tabanında hiçbir yerde zorlama açma (`!`) yok.
    static func random() -> LawQuote {
        all.randomElement() ?? LawQuote(
            id: -1,
            text: "Adalet mülkün temelidir.",
            author: "Türk adliye geleneği özdeyişi"
        )
    }
}
