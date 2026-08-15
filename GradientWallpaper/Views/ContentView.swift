import SwiftUI

enum SidebarSection: String, CaseIterable, Identifiable {
    case create = "Create"
    case presets = "Presets"
    case colors = "Colors"
    case gradients = "Gradients"
    case shapes = "Shapes"
    case effects = "Effects"
    case saved = "Saved"
    case settings = "Settings"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .create: return "wand.and.stars"
        case .presets: return "square.grid.2x2"
        case .colors: return "paintpalette"
        case .gradients: return "circle.lefthalf.filled"
        case .shapes: return "square.on.circle"
        case .effects: return "sparkles"
        case .saved: return "folder"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var vm: WallpaperEditorViewModel
    @State private var selectedSection: SidebarSection? = .create
    @State private var showExportSheet = false

    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.symbolName)
                    .tag(section)
            }
            .navigationTitle("Gradient Studio")
            .listStyle(.sidebar)
        } detail: {
            GeometryReader { proxy in
                let isCompact = proxy.size.width < 700
                Group {
                    if isCompact {
                        VStack(spacing: 0) {
                            PreviewCanvasView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            Divider()
                            editingPanel
                                .frame(height: min(proxy.size.height * 0.42, 420))
                        }
                    } else {
                        HStack(spacing: 0) {
                            editingPanel
                                .frame(width: min(max(proxy.size.width * 0.28, 320), 440))
                            Divider()
                            PreviewCanvasView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
            .toolbar { toolbarContent }
            .navigationTitle(vm.project.name)
            .sheet(isPresented: $showExportSheet) {
                ExportSheetView()
                    .environmentObject(vm)
            }
            .alert("Something went wrong", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var editingPanel: some View {
        switch selectedSection ?? .create {
        case .create: CreatePanelView()
        case .presets: PresetsGalleryView()
        case .colors: ColorsPanelView()
        case .gradients: GradientEditorView()
        case .shapes: ShapesPaletteView()
        case .effects: EffectsPaletteView()
        case .saved: SavedProjectsView()
        case .settings: SettingsView()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Button { vm.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                .disabled(!vm.canUndo)
                .keyboardShortcut("z", modifiers: .command)
            Button { vm.redo() } label: { Image(systemName: "arrow.uturn.forward") }
                .disabled(!vm.canRedo)
                .keyboardShortcut("z", modifiers: [.command, .shift])
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button { vm.randomize() } label: { Image(systemName: "shuffle") }
                .help("Randomize")
            Button { vm.resetToBlank() } label: { Image(systemName: "arrow.counterclockwise") }
                .help("Reset")
            Button { vm.saveProject() } label: { Image(systemName: "square.and.arrow.down") }
                .help("Save Project")
                .keyboardShortcut("s", modifiers: .command)
            Button {
                showExportSheet = true
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("e", modifiers: .command)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })
    }
}

#Preview {
    ContentView()
        .environmentObject(WallpaperEditorViewModel())
}
