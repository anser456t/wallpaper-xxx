import SwiftUI

struct ColorsPanelView: View {
    @EnvironmentObject var vm: WallpaperEditorViewModel
    @State private var selectedStopID: UUID?
    @State private var showSavePaletteDialog = false
    @State private var newPaletteName = ""

    var body: some View {
        ScrollView {
            PanelHeader(title: "Colors", subtitle: "Edit gradient stops and manage palettes")

            VStack(alignment: .leading, spacing: 20) {
                stopsSection
                if let binding = selectedColorBinding {
                    colorEditorSection(binding: binding)
                }
                recentColorsSection
                presetPalettesSection
                customPalettesSection

                Button {
                    vm.edit { $0.gradient = WallpaperGradient.randomized() }
                } label: {
                    Label("Randomize Colors", systemImage: "shuffle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .onAppear {
            if selectedStopID == nil {
                selectedStopID = vm.project.gradient.stops.first?.id
            }
        }
    }

    // MARK: Stops

    private var stopsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Gradient Stops").font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    vm.edit { $0.gradient.addStop(at: 0.5) }
                    selectedStopID = vm.project.gradient.stops.last?.id
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }

            GradientStopBar(
                gradient: vm.project.gradient,
                selectedStopID: $selectedStopID,
                onMove: { id, location in
                    vm.applyContinuousEdit { proj in
                        if let idx = proj.gradient.stops.firstIndex(where: { $0.id == id }) {
                            proj.gradient.stops[idx].location = location
                        }
                    }
                },
                onMoveEnded: { vm.commitContinuousEdit() }
            )
            .frame(height: 56)

            ForEach(vm.project.gradient.stops.sorted { $0.location < $1.location }) { stop in
                HStack {
                    Circle().fill(stop.color.color).frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.primary.opacity(0.15)))
                    Text("#\(stop.color.hexString)")
                        .font(.caption.monospaced())
                    Spacer()
                    Text("\(Int(stop.location * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if vm.project.gradient.stops.count > 2 {
                        Button {
                            vm.edit { $0.gradient.removeStop(id: stop.id) }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedStopID == stop.id ? Color.accentColor.opacity(0.15) : Color.clear)
                )
                .contentShape(Rectangle())
                .onTapGesture { selectedStopID = stop.id }
            }
        }
    }

    private var selectedColorBinding: Binding<CodableColor>? {
        guard let id = selectedStopID, let idx = vm.project.gradient.stops.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return Binding(
            get: { vm.project.gradient.stops[idx].color },
            set: { newColor in
                vm.applyContinuousEdit { proj in
                    proj.gradient.stops[idx].color = newColor
                }
            }
        )
    }

    // MARK: Color editor

    @ViewBuilder
    private func colorEditorSection(binding: Binding<CodableColor>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Color").font(.subheadline.weight(.semibold))

            ColorPicker("Full Color Picker", selection: Binding(
                get: { binding.wrappedValue.color },
                set: { newValue in
                    let updated = CodableColor(color: newValue)
                    binding.wrappedValue = updated
                    vm.commitContinuousEdit()
                    vm.registerRecentColor(updated)
                }
            ), supportsOpacity: true)

            HexRGBEditor(color: binding, onCommit: {
                vm.commitContinuousEdit()
                vm.registerRecentColor(binding.wrappedValue)
            })

            LabeledSlider(
                title: "Opacity",
                value: Binding(
                    get: { binding.wrappedValue.alpha },
                    set: { binding.wrappedValue.alpha = $0 }
                ),
                range: 0...1,
                format: "%.0f%%",
                onEditingChanged: { editing in if !editing { vm.commitContinuousEdit() } }
            )
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(uiColor: .secondarySystemGroupedBackground)))
    }

    // MARK: Recent colors

    private var recentColorsSection: some View {
        Group {
            if !vm.recentColors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Colors").font(.subheadline.weight(.semibold))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(vm.recentColors) { color in
                                ColorSwatchView(color: color.color, action: {
                                    applyColorToSelectedStop(color)
                                })
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: Preset palettes

    private var presetPalettesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preset Palettes").font(.subheadline.weight(.semibold))
            ForEach(ColorPalette.presets) { palette in
                paletteRow(palette, deletable: false)
            }
        }
    }

    private var customPalettesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Saved Palettes").font(.subheadline.weight(.semibold))
                Spacer()
                Button {
                    newPaletteName = ""
                    showSavePaletteDialog = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            if vm.customPalettes.isEmpty {
                Text("Save the current gradient's colors as a reusable palette.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(vm.customPalettes) { palette in
                paletteRow(palette, deletable: true)
            }
        }
        .alert("Save Palette", isPresented: $showSavePaletteDialog) {
            TextField("Palette name", text: $newPaletteName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let colors = vm.project.gradient.stops.map { $0.color }
                vm.saveCustomPalette(name: newPaletteName.isEmpty ? "Untitled Palette" : newPaletteName, colors: colors)
            }
        }
    }

    private func paletteRow(_ palette: ColorPalette, deletable: Bool) -> some View {
        HStack {
            HStack(spacing: -6) {
                ForEach(palette.colors.prefix(5)) { color in
                    Circle().fill(color.color).frame(width: 22, height: 22)
                        .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                }
            }
            Text(palette.name).font(.footnote)
            Spacer()
            Button("Apply") { applyPalette(palette) }
                .font(.caption)
                .buttonStyle(.bordered)
            if deletable {
                Button {
                    vm.deleteCustomPalette(palette)
                } label: {
                    Image(systemName: "trash").foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func applyPalette(_ palette: ColorPalette) {
        guard !palette.colors.isEmpty else { return }
        vm.edit { proj in
            let count = palette.colors.count
            proj.gradient.stops = palette.colors.enumerated().map { i, color in
                GradientStop(color: color, location: count > 1 ? Double(i) / Double(count - 1) : 0)
            }
        }
    }

    private func applyColorToSelectedStop(_ color: CodableColor) {
        guard let id = selectedStopID, let idx = vm.project.gradient.stops.firstIndex(where: { $0.id == id }) else { return }
        vm.edit { proj in
            proj.gradient.stops[idx].color = color
        }
    }
}
