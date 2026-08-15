import SwiftUI

struct ShapesPaletteView: View {
    @EnvironmentObject var vm: WallpaperEditorViewModel

    private var shapeKinds: [EffectKind] {
        EffectKind.allCases.filter { $0.category == .shape }
    }

    var body: some View {
        ScrollView {
            PanelHeader(title: "Shapes", subtitle: "Layer geometric and organic shapes over the gradient")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                ForEach(shapeKinds) { kind in
                    ChipButton(title: kind.displayName, systemImage: kind.symbolName, isSelected: false) {
                        vm.addEffect(kind)
                    }
                }
            }
            .padding(.horizontal)

            LayerStackView(filter: .shape)
                .padding(.top, 16)

            if let binding = vm.selectedEffectBinding, binding.wrappedValue.kind.category == .shape {
                EffectEditorView(effect: binding)
                    .padding(.top, 8)
            }
        }
        .padding(.bottom, 24)
    }
}
