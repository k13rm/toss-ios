import AuthenticationServices
import SwiftUI

struct TossBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.06, blue: 0.08), Color(red: 0.08, green: 0.12, blue: 0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(.teal.opacity(0.34))
                .frame(width: 260, height: 260)
                .blur(radius: 34)
                .offset(x: -110, y: -260)

            Circle()
                .fill(.orange.opacity(0.25))
                .frame(width: 280, height: 280)
                .blur(radius: 38)
                .offset(x: 130, y: 210)

            Circle()
                .fill(.indigo.opacity(0.22))
                .frame(width: 210, height: 210)
                .blur(radius: 34)
                .offset(x: 140, y: -130)
        }
    }
}

struct GlassPanel<Content: View>: View {
    var cornerRadius: CGFloat = 28
    var tint: Color? = nil
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding()
            .liquidGlass(cornerRadius: cornerRadius, tint: tint)
    }
}

extension View {
    @ViewBuilder
    func liquidGlass(cornerRadius: CGFloat = 24, tint: Color? = nil, interactive: Bool = true) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular.tint(tint).interactive(interactive), in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
        }
    }
}

struct GoogleLogo: View {
    var body: some View {
        ZStack {
            Circle().fill(.white)
            Text("G")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .red, .yellow, .green],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: 28, height: 28)
        .accessibilityLabel("Google logo")
    }
}

struct PrimaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
        }
        .buttonStyle(.borderedProminent)
        .tint(.teal)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct SettingsSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Picker("Mode", selection: $appState.appearanceMode) {
                        Text("Dark").tag("dark")
                        Text("Light").tag("light")
                        Text("System").tag("system")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Demo") {
                    Button("Reset onboarding") {
                        appState.resetDemo()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
