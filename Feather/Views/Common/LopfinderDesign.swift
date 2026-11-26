import SwiftUI

// MARK: - Lopfinder visual system

enum LopfinderPalette {
    static let indigo = Color(red: 0.34, green: 0.38, blue: 0.95)
    static let violet = Color(red: 0.55, green: 0.34, blue: 0.95)
    static let mint = Color(red: 0.20, green: 0.72, blue: 0.62)
    static let warning = Color(red: 0.95, green: 0.62, blue: 0.20)
    static let danger = Color(red: 0.92, green: 0.28, blue: 0.34)
    static let cardFill = Color(uiColor: .secondarySystemGroupedBackground)
    static let groupedFill = Color(uiColor: .systemGroupedBackground)
}

struct LopfinderCard<Content: View>: View {
    var tint: Color = LopfinderPalette.indigo
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LopfinderPalette.cardFill)
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(tint.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 12, y: 5)
    }
}

struct LopfinderSectionHeader: View {
    let eyebrow: String
    let title: String
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(LopfinderPalette.indigo)
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.title2.weight(.bold))
                Spacer()
                if let detail {
                    Text(detail)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

struct LopfinderStatusBadge: View {
    let title: String
    let systemImage: String
    var color: Color = LopfinderPalette.mint

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(color.opacity(0.12), in: Capsule())
    }
}

struct LopfinderEmptyState: View {
    let title: String
    let message: String
    let systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [LopfinderPalette.indigo, LopfinderPalette.violet],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .background(LopfinderPalette.indigo.opacity(0.10), in: Circle())
            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(LopfinderPalette.indigo)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

struct LopfinderMetric: View {
    let title: String
    let value: String
    let systemImage: String
    var color: Color = LopfinderPalette.indigo

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.headline.monospacedDigit())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
