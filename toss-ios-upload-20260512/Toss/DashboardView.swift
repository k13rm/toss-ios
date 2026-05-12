import SwiftUI

struct DashboardView: View {
    var body: some View {
        FunctionalDashboardView()
    }
}

struct DecisionButton: View {
    let title: String
    let emoji: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(emoji)
                    .font(.title2)
                Text(title)
                    .font(.caption.weight(.black))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
        }
        .foregroundStyle(.white)
        .buttonStyle(.plain)
        .background(color.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct StatTile: View {
    let emoji: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
            Text(value)
                .font(.title3.weight(.black))
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 92)
        .liquidGlass(cornerRadius: 22, tint: .white.opacity(0.08))
    }
}

struct RoomRow: View {
    let emoji: String
    let name: String
    let count: String

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.title)
                .frame(width: 48, height: 48)
                .liquidGlass(cornerRadius: 16, tint: .white.opacity(0.08))

            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline.weight(.black))
                Text(count)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .liquidGlass(cornerRadius: 24, tint: .white.opacity(0.06))
    }
}
