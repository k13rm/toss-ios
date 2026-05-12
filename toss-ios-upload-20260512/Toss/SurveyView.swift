import SwiftUI

struct SurveyView: View {
    @EnvironmentObject private var appState: AppState
    @State private var step = 0

    private let rooms = ["Bedroom", "Closet", "Kitchen", "Storage", "Whole home"]
    private let goals = ["Make quick decisions", "Prepare to move", "Sell more", "Donate more", "Find duplicates"]
    private let styles = ["Gentle push", "Be honest", "Money minded", "Space first"]

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Set up Toss")
                        .font(.largeTitle.weight(.black))
                    Text("A few taps so decisions feel less random.")
                        .foregroundStyle(.secondary)
                        .font(.callout.weight(.semibold))
                }

                Spacer()
            }
            .padding(.top, 16)

            ProgressView(value: Double(step + 1), total: 3)
                .tint(.teal)

            GlassPanel(cornerRadius: 32, tint: .teal.opacity(0.12)) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(questionTitle)
                        .font(.title2.weight(.black))

                    VStack(spacing: 10) {
                        ForEach(currentOptions, id: \.self) { option in
                            Button {
                                choose(option)
                            } label: {
                                HStack {
                                    Text(optionEmoji(option))
                                    Text(option)
                                        .font(.headline.weight(.bold))
                                    Spacer()
                                    if selectedValue == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.teal)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                            }
                            .foregroundStyle(.primary)
                            .liquidGlass(cornerRadius: 18, tint: selectedValue == option ? .teal.opacity(0.18) : nil)
                        }
                    }
                }
            }

            Spacer()

            PrimaryButton(title: step == 2 ? "See plans" : "Next", systemImage: "arrow.right") {
                if step < 2 {
                    step += 1
                } else {
                    appState.hasCompletedSurvey = true
                }
            }
        }
        .padding(.horizontal, 20)
        .safeAreaPadding(.top, 20)
        .safeAreaPadding(.bottom, 22)
        .animation(.snappy(duration: 0.28), value: step)
    }

    private var questionTitle: String {
        switch step {
        case 0: "Where should Toss help first?"
        case 1: "What is your main goal?"
        default: "How direct should the AI be?"
        }
    }

    private var currentOptions: [String] {
        switch step {
        case 0: rooms
        case 1: goals
        default: styles
        }
    }

    private var selectedValue: String {
        switch step {
        case 0: appState.selectedRoom
        case 1: appState.clutterGoal
        default: appState.decisionStyle
        }
    }

    private func choose(_ option: String) {
        switch step {
        case 0: appState.selectedRoom = option
        case 1: appState.clutterGoal = option
        default: appState.decisionStyle = option
        }
    }

    private func optionEmoji(_ option: String) -> String {
        [
            "Bedroom": "🛏️",
            "Closet": "👕",
            "Kitchen": "🍳",
            "Storage": "📦",
            "Whole home": "🏠",
            "Make quick decisions": "⚡️",
            "Prepare to move": "🚚",
            "Sell more": "💸",
            "Donate more": "🎁",
            "Find duplicates": "🔎",
            "Gentle push": "🌤️",
            "Be honest": "🎯",
            "Money minded": "🧾",
            "Space first": "🫧"
        ][option, default: "✨"]
    }
}
