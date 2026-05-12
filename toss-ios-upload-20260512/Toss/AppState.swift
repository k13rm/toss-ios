import SwiftUI

final class AppState: ObservableObject {
    @AppStorage("hasLoggedIn") var hasLoggedIn = false
    @AppStorage("hasCompletedSurvey") var hasCompletedSurvey = false
    @AppStorage("hasStartedTrial") var hasStartedTrial = false
    @AppStorage("appearanceMode") var appearanceMode = "dark"
    @Published var selectedRoom = "Bedroom"
    @Published var clutterGoal = "Make quick decisions"
    @Published var decisionStyle = "Gentle push"

    var colorScheme: ColorScheme? {
        appearanceMode == "system" ? nil : appearanceMode == "light" ? .light : .dark
    }

    func resetDemo() {
        hasLoggedIn = false
        hasCompletedSurvey = false
        hasStartedTrial = false
    }
}
