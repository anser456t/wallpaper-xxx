import SwiftUI

struct CreatePanelView: View {
    @EnvironmentObject var vm: WallpaperEditorViewModel
    @State private var nameDraft: String = ""

    var body: some View {
        ScrollView {
            PanelHeader(title: "Create", subtitle: "Start a new wallpaper or fine-tune this one")

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name").font(.subheadline.weight(.semibold))
                    TextField("Wallpaper name", text: nameBinding)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Canvas Size").font(.subheadline.weight(.semibold))
                    canvasSizeMenu
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Gradient Type").font(.subheadline.weight(.semibold))
                    gradientTypeGrid
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Actions").font(.subheadline.weight(.semibold))
                    VStack(spacing: 10) {
                        Button {
                            vm.randomize()
                        } label: {
                            Label("Randomize Wallpaper", systemImage: "shuffle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            vm.saveProject()
                        } label: {
                            Label("Save Project", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Layers").font(.subheadline.weight(.semibold))
                    Text("\(vm.project.effects.count) effect\(vm.project.effects.count == 1 ? "" : "s") on this wallpaper")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .onAppear { nameDraft = vm.project.name }
    }

    private var nameBinding: Binding<String> {
        Binding(
            get: { vm.project.name },
            set: { newValue in vm.edit { $0.name = newValue } }
        )
    }

    private var canvasSizeMenu: some View {
        Menu {
            ForEach(CanvasSize.presets) { size in
                Button {
                    vm.edit { $0.canvasSize = size }
                } label: {
                    Text("\(size.name) — \(size.width)×\(size.height)")
                }
            }
        } label: {
            HStack {
                Text("\(vm.project.canvasSize.name)")
                Spacer()
                Text("\(vm.project.canvasSize.width)×\(vm.project.canvasSize.height)")
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(uiColor: .tertiarySystemFill)))
        }
        .menuStyle(.automatic)
    }

    private var gradientTypeGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
            ForEach(GradientKind.allCases) { kind in
                ChipButton(
                    title: kind.displayName,
                    systemImage: kind.symbolName,
                    isSelected: vm.project.gradient.kind == kind
                ) {
                    vm.edit { $0.gradient.kind = kind }
                }
            }
        }
    }
}
