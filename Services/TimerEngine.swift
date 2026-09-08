// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import Foundation
import Combine

/// Aktif sınavdaki saati yürütür.
/// - `.hmgsStandard`: `limitSeconds`'tan geriye sayar, sıfırda `onTimeExpired` tetikler.
/// - `.untimed`: yukarı sayar; bitişte kaydedilen/gösterilen değer bu.
///
/// Sağlamlık notları:
/// - Geçen süre `Date` farkından hesaplanıyor, tik sayısından değil: uygulama arka
///   plana atılıp geri geldiğinde saat "durmuş" görünmüyor.
/// - Kullanıcı cihaz saatini geri alırsa geçen süre AZALMIYOR (monotonik kilit).
/// - `onTimeExpired` en fazla bir kez çağrılıyor; eski sürümde süre dolarken
///   kullanıcı da "Bitir"e basarsa sınav iki kez bitirilebiliyordu.
@MainActor
final class TimerEngine: ObservableObject {
    @Published private(set) var displaySeconds: Int = 0
    @Published private(set) var isRunning = false
    @Published private(set) var hasExpired = false

    // `nonisolated(unsafe)`: yalnızca ana iş parçacığından dokunuluyor ama `deinit`
    // izole olmadığı için derleyicinin buna izin vermesi gerekiyor. Amaç, ekran
    // kapanınca RunLoop'ta öksüz kalmış bir Timer bırakmamak.
    private nonisolated(unsafe) var timer: Timer?
    private var segmentStart: Date?
    private var accumulated: TimeInterval
    private var lastReportedElapsed: TimeInterval
    private let mode: TimeMode
    private let limitSeconds: Int?

    var onTimeExpired: (() -> Void)?

    /// - Parameter alreadyElapsedSeconds: yarım kalmış bir sınav sürdürülüyorsa
    ///   daha önce geçmiş süre.
    init(mode: TimeMode, limitSeconds: Int?, alreadyElapsedSeconds: TimeInterval = 0) {
        self.mode = mode
        self.limitSeconds = limitSeconds
        self.accumulated = max(0, alreadyElapsedSeconds)
        self.lastReportedElapsed = max(0, alreadyElapsedSeconds)
        self.displaySeconds = Self.displayValue(mode: mode, limit: limitSeconds, elapsed: accumulated)
    }

    deinit {
        timer?.invalidate()
    }

    var elapsedSeconds: TimeInterval {
        guard let segmentStart else { return lastReportedElapsed }
        let candidate = accumulated + Date().timeIntervalSince(segmentStart)
        // Saat geriye alınsa bile geçen süre asla azalmaz.
        return max(lastReportedElapsed, candidate)
    }

    func start() {
        guard !isRunning, !hasExpired else { return }
        isRunning = true
        segmentStart = Date()
        // .common mode: kullanıcı listeyi kaydırırken de saat işlemeye devam etsin.
        // Timer aşağıda RunLoop.main'e ekleniyor, yani bu blok GARANTİ olarak ana
        // iş parçacığında çalışıyor. `assumeIsolated` bunu derleyiciye anlatıyor;
        // her tikte bir `Task` açmaktan da kurtuluyoruz.
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated { self.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        tick()
    }

    /// Duraklat (uygulama arka plana giderken) — geçen süre korunur.
    func pause() {
        guard isRunning else { return }
        lastReportedElapsed = elapsedSeconds
        accumulated = lastReportedElapsed
        segmentStart = nil
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    /// Sınav biterken çağrılır; toplam geçen süreyi döner.
    @discardableResult
    func stop() -> TimeInterval {
        let elapsed = elapsedSeconds
        lastReportedElapsed = elapsed
        accumulated = elapsed
        segmentStart = nil
        timer?.invalidate()
        timer = nil
        isRunning = false
        return elapsed
    }

    private func tick() {
        let elapsed = elapsedSeconds
        lastReportedElapsed = elapsed
        displaySeconds = Self.displayValue(mode: mode, limit: limitSeconds, elapsed: elapsed)

        guard mode == .hmgsStandard, let limit = limitSeconds, !hasExpired else { return }
        if elapsed >= Double(limit) {
            hasExpired = true
            stop()
            onTimeExpired?()
        }
    }

    private static func displayValue(mode: TimeMode, limit: Int?, elapsed: TimeInterval) -> Int {
        switch mode {
        case .untimed:
            return max(0, Int(elapsed))
        case .hmgsStandard:
            return max(0, (limit ?? 0) - Int(elapsed))
        }
    }

    /// Üst çubuktaki gösterim. Bir saati aşan süreler (155 dakikalık tam deneme)
    /// "02:35:00" biçiminde gösteriliyor — eski kod "155:00" yazıyordu.
    var formatted: String {
        Self.format(seconds: displaySeconds)
    }

    /// `nonisolated`: saf biçimlendirme, ana iş parçacığına bağlı değil —
    /// testlerden ve ileride arka plandan da çağrılabilsin.
    nonisolated static func format(seconds: Int) -> String {
        let safe = max(0, seconds)
        let hours = safe / 3600
        let minutes = (safe % 3600) / 60
        let secs = safe % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    /// VoiceOver için okunabilir süre — "02:35" yerine "2 dakika 35 saniye".
    var accessibilityText: String {
        Self.accessibilityText(seconds: displaySeconds, isCountdown: mode == .hmgsStandard)
    }

    nonisolated static func accessibilityText(seconds: Int, isCountdown: Bool) -> String {
        let safe = max(0, seconds)
        let hours = safe / 3600
        let minutes = (safe % 3600) / 60
        let secs = safe % 60
        var parts: [String] = []
        if hours > 0 { parts.append("\(hours) saat") }
        if minutes > 0 { parts.append("\(minutes) dakika") }
        if secs > 0 || parts.isEmpty { parts.append("\(secs) saniye") }
        let body = parts.joined(separator: " ")
        return isCountdown ? "Kalan süre: \(body)" : "Geçen süre: \(body)"
    }
}
