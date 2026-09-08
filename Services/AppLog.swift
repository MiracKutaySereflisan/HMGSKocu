// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import Foundation
import os

/// Geliştirici günlüğü.
///
/// KURAL: Buraya kişisel veri YAZILMAZ — kullanıcının adı, çözdüğü sorular,
/// puanları asla loglanmaz. Yalnızca teknik bilgi (hangi dosya, hangi hata tipi).
/// `.debug` seviyesi sistem tarafından kalıcı olarak saklanmaz, yani cihazda iz
/// bırakmaz; yayın yapısında da görünmez.
enum AppLog {
    private static let persistence = Logger(subsystem: "com.mirackutay.HMGSKocu", category: "persistence")

    /// Kurtarmalı okumada kaç kayıt atıldı. Kayıtların İÇERİĞİ asla loglanmaz;
    /// yalnızca dosya adı ve sayılar.
    static func recordsDropped(file: String, dropped: Int, kept: Int) {
        guard dropped > 0 else { return }
        persistence.debug("\(file, privacy: .public): \(dropped, privacy: .public) okunamayan kayıt atıldı, \(kept, privacy: .public) kayıt korundu")
    }

    static func persistenceIssue(_ operation: String, _ error: Error) {
        persistence.debug("\(operation, privacy: .public) başarısız: \(String(describing: type(of: error)), privacy: .public)")
    }
}
