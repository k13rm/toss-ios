import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 42)

            VStack(spacing: 14) {
                Text("🧺")
                    .font(.system(size: 76))
                    .frame(width: 116, height: 116)
                    .liquidGlass(cornerRadius: 36, tint: .teal.opacity(0.15))
                    .symbolEffect(.bounce, value: appState.hasLoggedIn)

                Text("Toss")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .tracking(0)

                Text("Point. Decide. Make room.")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { _ in
                    appState.hasLoggedIn = true
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    appState.hasLoggedIn = true
                } label: {
                    HStack(spacing: 12) {
                        GoogleLogo()
                        Text("Sign in with Google")
                            .font(.headline.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .foregroundStyle(.primary)
                .liquidGlass(cornerRadius: 18, tint: .white.opacity(0.1))

                Button("Continue with demo") {
                    appState.hasLoggedIn = true
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }

            Text("10 days free, then your selected Apple subscription renews automatically unless cancelled.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
        .safeAreaPadding(.top, 18)
        .safeAreaPadding(.bottom, 20)
    }
}
