import SwiftUI

/// A labeled slider row with a live numeric readout, matching the compact
/// style used throughout every editing panel.
struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    var format: String = "%.0f"
    var onEditingChanged: ((Bool) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(String(format: format, value))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range) { editing in
                onEditingChanged?(editing)
            }
        }
    }
}

/// A round tappable color swatch used in recent-colors rows and palettes.
struct ColorSwatchView: View {
    let color: Color
    var size: CGFloat = 32
    var isSelected: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .overlay(
                    Circle().strokeBorder(Color.primary.opacity(isSelected ? 0.8 : 0.15), lineWidth: isSelected ? 2 : 1)
                )
                .overlay(
                    Circle().strokeBorder(Color(uiColor: .systemBackground), lineWidth: isSelected ? 2 : 0)
                        .padding(2)
                )
        }
        .buttonStyle(.plain)
    }
}

/// Section header used at the top of each sidebar editing panel.
struct PanelHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title2.bold())
            if let subtitle {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}

/// A small rounded chip used for gradient-kind and blend-mode pickers.
struct ChipButton: View {
    let title: String
    let systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.footnote.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isSelected ? Color.accentColor : Color(uiColor: .tertiarySystemFill))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

/// Card used inside preset/effect galleries showing a gradient thumbnail.
struct ThumbnailCard<Content: View>: View {
    let title: String
    let isSelected: Bool
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.clear)
                .overlay(content)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.08), lineWidth: isSelected ? 3 : 1)
                )
                .aspectRatio(0.8, contentMode: .fit)

            Text(title)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
    }
}
