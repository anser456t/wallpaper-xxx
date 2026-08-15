import SwiftUI

struct EffectEditorView: View {
    @EnvironmentObject var vm: WallpaperEditorViewModel
    @Binding var effect: WallpaperEffect

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Edit \(effect.kind.displayName)")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal)

            VStack(spacing: 12) {
                if effect.kind.category == .shape {
                    geometryControls
                }

                colorControl

                LabeledSlider(title: "Opacity", value: $effect.opacity, range: 0...1, format: "%.0f%%", onEditingChanged: commit)

                if effect.kind.category == .shape {
                    LabeledSlider(title: "Feather", value: $effect.featherAmount, range: 0...1, format: "%.2f", onEditingChanged: commit)
                }

                if [.blur, .glow, .radialGlow, .colorBloom, .glass, .liquid, .aurora].contains(effect.kind) {
                    LabeledSlider(title: "Blur Radius", value: $effect.blurRadius, range: 0...200, format: "%.0f", onEditingChanged: commit)
                }

                if [.noise, .grain, .vignette, .liquid, .aurora].contains(effect.kind) {
                    LabeledSlider(title: "Intensity", value: $effect.intensity, range: 0...1, format: "%.2f", onEditingChanged: commit)
                }

                if effect.kind == .roundedRect {
                    LabeledSlider(title: "Corner Radius", value: $effect.cornerRadius, range: 0...200, format: "%.0f", onEditingChanged: commit)
                }

                blendModePicker
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    private var geometryControls: some View {
        VStack(spacing: 10) {
            LabeledSlider(title: "X Position", value: $effect.x, range: 0...1, format: "%.2f", onEditingChanged: commit)
            LabeledSlider(title: "Y Position", value: $effect.y, range: 0...1, format: "%.2f", onEditingChanged: commit)
            LabeledSlider(title: "Width", value: $effect.width, range: 0.02...1.5, format: "%.2f", onEditingChanged: commit)
            LabeledSlider(title: "Height", value: $effect.height, range: 0.02...1.5, format: "%.2f", onEditingChanged: commit)
            LabeledSlider(title: "Rotation", value: $effect.rotationDegrees, range: 0...360, format: "%.0f°", onEditingChanged: commit)
        }
    }

    private var colorControl: some View {
        HStack {
            Text("Color").font(.subheadline)
            Spacer()
            ColorPicker("", selection: Binding(
                get: { effect.color.color },
                set: { newValue in
                    vm.beginContinuousEdit()
                    effect.color = CodableColor(color: newValue)
                    vm.commitContinuousEdit()
                }
            ), supportsOpacity: true)
            .labelsHidden()
        }
    }

    private var blendModePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Blend Mode").font(.subheadline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EffectBlendMode.allCases) { mode in
                        ChipButton(title: mode.displayName, systemImage: nil, isSelected: effect.blendMode == mode) {
                            vm.beginContinuousEdit()
                            effect.blendMode = mode
                            vm.commitContinuousEdit()
                        }
                    }
                }
            }
        }
    }

    private func commit(_ editing: Bool) {
        if editing {
            vm.beginContinuousEdit()
        } else {
            vm.commitContinuousEdit()
        }
    }
}
