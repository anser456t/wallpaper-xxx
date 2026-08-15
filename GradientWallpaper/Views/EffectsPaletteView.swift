import SwiftUI

struct EffectsPaletteView: View {
    @EnvironmentObject var vm: WallpaperEditorViewModel

    private var effectKinds: [EffectKind] {
        EffectKind.allCases.filter { $0.category == .postProcess }
    }

    var body: some View {
        ScrollView {
            PanelHeader(title: "Effects", subtitle: "Grain, glow, blur, and atmosphere passes")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                ForEach(effectKinds) { kind in
                    ChipButton(title: kind.displayName, systemImage: kind.symbolName, isSelected: false) {
                        vm.addEffect(kind)
                    }
                }
            }
            .padding(.horizontal)

            LayerStackView(filter: .postProcess)
                .padding(.top, 16)

            if let binding = vm.selectedEffectBinding, binding.wrappedValue.kind.category == .postProcess {
                EffectEditorView(effect: binding)
                    .padding(.top, 8)
            }
        }
        .padding(.bottom, 24)
    }
}
