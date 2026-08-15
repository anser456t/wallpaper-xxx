import SwiftUI

struct GradientEditorView: View {
    @EnvironmentObject var vm: WallpaperEditorViewModel

    var body: some View {
        ScrollView {
            PanelHeader(title: "Gradients", subtitle: "Shape the ramp — drag on canvas to move the center")

            VStack(alignment: .leading, spacing: 18) {
                kindPicker

                switch vm.project.gradient.kind {
                case .linear:
                    linearControls
                case .radial, .reflected:
                    radialControls
                case .angular:
                    angularControls
                case .diamond:
                    diamondControls
                case .mesh:
                    meshControls
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    private var kindPicker: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
            ForEach(GradientKind.allCases) { kind in
                ChipButton(title: kind.displayName, systemImage: kind.symbolName, isSelected: vm.project.gradient.kind == kind) {
                    vm.edit { $0.gradient.kind = kind }
                }
            }
        }
    }

    // MARK: Linear

    private var linearControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Direction").font(.subheadline.weight(.semibold))
            HStack(spacing: 8) {
                ForEach(directionPresets, id: \.0) { label, angle in
                    ChipButton(title: label, systemImage: nil, isSelected: abs(vm.project.gradient.angleDegrees - angle) < 0.5) {
                        vm.edit { $0.gradient.angleDegrees = angle }
                    }
                }
            }
            LabeledSlider(
                title: "Angle",
                value: continuousBinding(\.angleDegrees),
                range: 0...360,
                format: "%.0f°",
                onEditingChanged: commitIfEnded
            )
            LabeledSlider(
                title: "Spread",
                value: continuousBinding(\.spread),
                range: 0.2...2,
                format: "%.2f×",
                onEditingChanged: commitIfEnded
            )
        }
    }

    private var directionPresets: [(String, Double)] {
        [("→", 0), ("↘", 45), ("↓", 90), ("↙", 135), ("←", 180), ("↖", 225), ("↑", 270), ("↗", 315)]
    }

    // MARK: Radial / Reflected

    private var radialControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            positionSliders
            LabeledSlider(title: "Radius", value: continuousBinding(\.radius), range: 0.1...2, format: "%.2f", onEditingChanged: commitIfEnded)
            LabeledSlider(title: "Aspect Ratio", value: continuousBinding(\.aspectRatio), range: 0.3...3, format: "%.2f", onEditingChanged: commitIfEnded)
            LabeledSlider(title: "Spread", value: continuousBinding(\.spread), range: 0.2...2, format: "%.2f×", onEditingChanged: commitIfEnded)
        }
    }

    // MARK: Angular

    private var angularControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            positionSliders
            LabeledSlider(title: "Start Angle", value: continuousBinding(\.startAngleDegrees), range: 0...360, format: "%.0f°", onEditingChanged: commitIfEnded)
            LabeledSlider(title: "Rotation", value: continuousBinding(\.rotationDegrees), range: 0...360, format: "%.0f°", onEditingChanged: commitIfEnded)
        }
    }

    // MARK: Diamond

    private var diamondControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            positionSliders
            LabeledSlider(title: "Radius", value: continuousBinding(\.radius), range: 0.1...2, format: "%.2f", onEditingChanged: commitIfEnded)
        }
    }

    // MARK: Mesh

    private var meshControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Mesh Points").font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    vm.edit { proj in
                        proj.gradient.meshPoints.append(
                            MeshPoint(x: Double.random(in: 0.2...0.8), y: Double.random(in: 0.2...0.8), color: CodableColor.random())
                        )
                    }
                } label: { Image(systemName: "plus.circle.fill") }
            }
            ForEach(Array(vm.project.gradient.meshPoints.enumerated()), id: \.element.id) { index, point in
                HStack {
                    ColorPicker("", selection: Binding(
                        get: { point.color.color },
                        set: { newColor in
                            vm.edit { $0.gradient.meshPoints[index].color = CodableColor(color: newColor) }
                        }
                    ))
                    .labelsHidden()
                    .frame(width: 32)

                    VStack {
                        LabeledSlider(title: "X", value: meshPointBinding(index, \.x), range: 0...1, format: "%.2f", onEditingChanged: commitIfEnded)
                        LabeledSlider(title: "Y", value: meshPointBinding(index, \.y), range: 0...1, format: "%.2f", onEditingChanged: commitIfEnded)
                    }

                    if vm.project.gradient.meshPoints.count > 2 {
                        Button {
                            vm.edit { $0.gradient.meshPoints.remove(at: index) }
                        } label: { Image(systemName: "trash").foregroundStyle(.red) }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(uiColor: .secondarySystemGroupedBackground)))
            }
        }
    }

    private func meshPointBinding(_ index: Int, _ keyPath: WritableKeyPath<MeshPoint, Double>) -> Binding<Double> {
        Binding(
            get: { vm.project.gradient.meshPoints[index][keyPath: keyPath] },
            set: { newValue in
                vm.applyContinuousEdit { $0.gradient.meshPoints[index][keyPath: keyPath] = newValue }
            }
        )
    }

    // MARK: Shared

    private var positionSliders: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Center Position").font(.subheadline.weight(.semibold))
            LabeledSlider(title: "X", value: continuousBinding(\.centerX), range: 0...1, format: "%.2f", onEditingChanged: commitIfEnded)
            LabeledSlider(title: "Y", value: continuousBinding(\.centerY), range: 0...1, format: "%.2f", onEditingChanged: commitIfEnded)
        }
    }

    private func continuousBinding(_ keyPath: WritableKeyPath<WallpaperGradient, Double>) -> Binding<Double> {
        Binding(
            get: { vm.project.gradient[keyPath: keyPath] },
            set: { newValue in
                vm.applyContinuousEdit { $0.gradient[keyPath: keyPath] = newValue }
            }
        )
    }

    private func commitIfEnded(_ editing: Bool) {
        if !editing { vm.commitContinuousEdit() }
    }
}
