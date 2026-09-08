// Copyright (c) 2026 Mirac Kutay Sereflisan. Tum haklari saklidir.
import SwiftUI

/// Sınav başlatmanın TEK yolu. Dört ekran (Ana Sayfa, Sınav, Havuz, Yolculuk)
/// aynı hedefi kullanıyor; böylece "hangi ekran nasıl başlatıyordu" diye
/// hatırlamak gerekmiyor ve bir düzeltme dört yerde tekrarlanmıyor.
extension View {
    /// `@MainActor` açıkça yazılı: içeride bir `@MainActor` ViewModel kuruluyor,
    /// izolasyonun çıkarıma bırakılmaması gerekiyor.
    @MainActor
    func examDestination(
        _ launch: Binding<ExamLaunch?>,
        journeyViewModel: JourneyViewModel? = nil
    ) -> some View {
        navigationDestination(item: launch) { item in
            ActiveExamView(
                viewModel: ActiveExamViewModel(
                    configuration: item.configuration,
                    explicitQuestionIDs: item.explicitQuestionIDs,
                    resuming: item.resuming
                ),
                journeyViewModel: journeyViewModel
            )
        }
    }
}
