import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            TossBackground()

            if !appState.hasLoggedIn {
                LoginView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if !appState.hasCompletedSurvey {
                SurveyView()
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            } else if !appState.hasStartedTrial {
                PaywallView()
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            } else {
                DashboardView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.snappy(duration: 0.42), value: appState.hasLoggedIn)
        .animation(.snappy(duration: 0.42), value: appState.hasCompletedSurvey)
        .animation(.snappy(duration: 0.42), value: appState.hasStartedTrial)
    }
}
