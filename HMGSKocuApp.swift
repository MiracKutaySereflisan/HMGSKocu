// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import SwiftUI

@main
struct HMGSKocuApp: App {
    @StateObject private var store = AppDataStore.shared

    @AppStorage(DefaultsKey.appearance) private var appearanceRaw = AppAppearance.system.rawValue
    @AppStorage(DefaultsKey.hasSeenAppTour) private var hasSeenAppTour = false
    @AppStorage(DefaultsKey.hasAcceptedContentNotice) private var hasAcceptedContentNotice = false

    /// Açılış akışı tek bir enum'la yürüyor. Eski kodda bu üç ayrı bool + iki
    /// sunum (alert + fullScreenCover) ile yapılıyordu ve sıralama şansa kalmıştı
    /// (isim diyaloğu açılış ekranının üstüne biniyordu).
    @State private var stage: LaunchStage = .splash

    private enum LaunchStage {
        case splash
        case welcome
        case tour
        case ready
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootTabView()
                    .environmentObject(store)

                switch stage {
                case .splash:
                    SplashView { advanceFromSplash() }
                        .transition(.opacity)
                        .zIndex(3)
                case .welcome:
                    WelcomeView { name in
                        store.setDisplayName(name)
                        hasAcceptedContentNotice = true
                        stage = hasSeenAppTour ? .ready : .tour
                    }
                    .transition(.opacity)
                    .zIndex(2)
                case .tour:
                    AppTourView {
                        hasSeenAppTour = true
                        stage = .ready
                    }
                    .transition(.opacity)
                    .zIndex(2)
                case .ready:
                    EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.28), value: stage)
            .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch AppAppearance(rawValue: appearanceRaw) ?? .system {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    private func advanceFromSplash() {
        if !store.hasProfile || !hasAcceptedContentNotice {
            stage = .welcome
        } else if !hasSeenAppTour {
            stage = .tour
        } else {
            stage = .ready
        }
    }
}
