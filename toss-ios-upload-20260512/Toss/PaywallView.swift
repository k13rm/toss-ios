import StoreKit
import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var appState: AppState
    private let productIDs = ["toss.basic.monthly", "toss.pro.monthly", "toss.max.monthly"]

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 10) {
                Text("💎")
                    .font(.system(size: 62))
                    .frame(width: 96, height: 96)
                    .liquidGlass(cornerRadius: 32, tint: .teal.opacity(0.16))

                Text("Start 10 days free")
                    .font(.largeTitle.weight(.black))
                    .multilineTextAlignment(.center)

                Text("Then your selected Apple subscription renews automatically. Cancel anytime before renewal in Apple ID settings.")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            PlanList()

            if #available(iOS 17.0, *) {
                SubscriptionStoreView(productIDs: productIDs) {
                    VStack(spacing: 8) {
                        Text("Apple subscription checkout")
                            .font(.headline.weight(.black))
                        Text("Connect these product IDs in App Store Connect with a 10 day introductory offer.")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
                .subscriptionStorePolicyDestination(url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!, for: .termsOfService)
                .subscriptionStorePolicyDestination(url: URL(string: "https://www.apple.com/legal/privacy/")!, for: .privacyPolicy)
                .storeButton(.visible, for: .restorePurchases)
                .liquidGlass(cornerRadius: 32, tint: .white.opacity(0.08))
            } else {
                Text("Apple subscription checkout requires iOS 17 or later.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            PrimaryButton(title: "Start 10-day trial", systemImage: "sparkles") {
                appState.hasStartedTrial = true
            }

            Text("In production, the 10 day free trial is configured in App Store Connect for each subscription product.")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 6)
        }
        .padding(.horizontal, 20)
        .safeAreaPadding(.top, 18)
        .safeAreaPadding(.bottom, 22)
    }
}

struct PlanList: View {
    var body: some View {
        VStack(spacing: 12) {
            PlanRow(name: "Basic", price: "$3.99/mo", detail: "50 scans, simple decisions, saved history", emoji: "🌱")
            PlanRow(name: "Pro", price: "$7.99/mo", detail: "Unlimited scans, resale drafts, smart rooms", emoji: "✨", featured: true)
            PlanRow(name: "Max", price: "$14.99/mo", detail: "Family sharing, moving mode, insurance vault", emoji: "💎")
        }
    }
}

struct PlanRow: View {
    let name: String
    let price: String
    let detail: String
    let emoji: String
    var featured = false

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline.weight(.black))
                Text(detail)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(price)
                .font(.headline.weight(.black))
        }
        .padding()
        .liquidGlass(cornerRadius: 22, tint: featured ? .teal.opacity(0.18) : nil)
    }
}
