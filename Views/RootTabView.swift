// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import SwiftUI

struct RootTabView: View {
    /// Sekme seçimi dışarıdan da değiştirilebilsin diye durum burada tutuluyor
    /// (örn. sonuç ekranındaki "Ana Sayfaya Dön" gerçekten ana sayfaya götürsün).
    @State private var selection: Tab = .journey

    enum Tab: Hashable {
        case journey, home, exam, pool, profile
    }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { JourneyMapView() }
                .tabItem { Label("Yolculuk", systemImage: "map.fill") }
                .tag(Tab.journey)

            NavigationStack { DashboardView() }
                .tabItem { Label("Ana Sayfa", systemImage: "house.fill") }
                .tag(Tab.home)

            NavigationStack { ExamSetupView() }
                .tabItem { Label("Sınav", systemImage: "doc.text.fill") }
                .tag(Tab.exam)

            NavigationStack { MistakePoolView() }
                .tabItem { Label("Havuz", systemImage: "exclamationmark.triangle.fill") }
                .tag(Tab.pool)

            NavigationStack { ProfileView() }
                .tabItem { Label("Profil", systemImage: "person.crop.circle.fill") }
                .tag(Tab.profile)
        }
        .tint(HMGSTheme.Colors.accent)
    }
}

#Preview {
    RootTabView()
}
