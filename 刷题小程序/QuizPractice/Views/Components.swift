import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbolName)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
}

struct ActionLabel: View {
    let title: String
    let symbolName: String

    var body: some View {
        Label(title, systemImage: symbolName)
            .font(.headline)
            .frame(maxWidth: .infinity)
    }
}

struct OptionRow: View {
    let option: Choice
    let isSelected: Bool
    let isMultiple: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(isSelected ? .blue : .secondary)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(option.key)
                    .font(.caption.weight(.bold))
                    .foregroundColor(isSelected ? .blue : .secondary)

                Text(option.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(isSelected ? Color.blue.opacity(0.12) : Color(.secondarySystemGroupedBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
        )
        .cornerRadius(8)
    }

    private var iconName: String {
        if isMultiple {
            return isSelected ? "checkmark.square.fill" : "square"
        }
        return isSelected ? "largecircle.fill.circle" : "circle"
    }
}

struct ReviewOptionRow: View {
    let option: Choice
    let isSelected: Bool
    let isAnswer: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 4) {
                Text(option.key)
                    .font(.caption.weight(.bold))
                    .foregroundColor(color)

                Text(option.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(backgroundColor)
        .cornerRadius(8)
    }

    private var color: Color {
        if isAnswer { return .green }
        if isSelected { return .red }
        return .secondary
    }

    private var backgroundColor: Color {
        if isAnswer { return Color.green.opacity(0.12) }
        if isSelected { return Color.red.opacity(0.10) }
        return Color(.secondarySystemGroupedBackground)
    }

    private var symbolName: String {
        if isAnswer { return "checkmark.circle.fill" }
        if isSelected { return "xmark.circle.fill" }
        return "circle"
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 15)
            .padding(.horizontal, 16)
            .background(color.opacity(configuration.isPressed ? 0.75 : 1))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(tint.opacity(configuration.isPressed ? 0.20 : 0.12))
            .foregroundColor(tint)
            .cornerRadius(8)
    }
}
