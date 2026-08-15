import SwiftUI

/// Lists the effects on the current project matching `filter`, letting the
/// user select, reorder, toggle visibility, duplicate, and delete layers.
struct LayerStackView: View {
    @EnvironmentObject var vm: WallpaperEditorViewModel
    let filter: EffectCategory

    private var filteredIndices: [Int] {
        vm.project.effects.indices.filter { vm.project.effects[$0].kind.category == filter }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Layers").font(.subheadline.weight(.semibold))
                Spacer()
                if vm.selectedEffectID != nil {
                    Button {
                        vm.duplicateSelectedEffect()
                    } label: { Image(systemName: "plus.square.on.square") }
                        .buttonStyle(.plain)
                    Button {
                        vm.deleteSelectedEffect()
                    } label: { Image(systemName: "trash").foregroundStyle(.red) }
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            if filteredIndices.isEmpty {
                Text("No layers yet — tap a shape or effect above to add one.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 6) {
                    ForEach(filteredIndices, id: \.self) { index in
                        layerRow(index: index)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func layerRow(index: Int) -> some View {
        let effect = vm.project.effects[index]
        return HStack {
            Image(systemName: effect.kind.symbolName)
                .frame(width: 22)
            Text(effect.kind.displayName)
                .font(.footnote)
            Spacer()
            Button {
                vm.edit { $0.effects[index].isVisible.toggle() }
            } label: {
                Image(systemName: effect.isVisible ? "eye" : "eye.slash")
                    .foregroundStyle(effect.isVisible ? .primary : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(vm.selectedEffectID == effect.id ? Color.accentColor.opacity(0.15) : Color(uiColor: .secondarySystemGroupedBackground))
        )
        .contentShape(Rectangle())
        .onTapGesture { vm.selectedEffectID = effect.id }
    }
}
