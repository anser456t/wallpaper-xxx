import SwiftUI
import Combine

/// Owns the currently-edited `WallpaperProject`, drives live preview
/// rendering off the main thread, and exposes undo/redo, persistence, and
/// export actions to every view in the app.
@MainActor
final class WallpaperEditorViewModel: ObservableObject {

    @Published var project: WallpaperProject
    @Published private(set) var previewImage: CGImage?
    @Published var selectedEffectID: WallpaperEffect.ID?
    @Published var isRendering: Bool = false
    @Published var errorMessage: String?
    @Published var customPalettes: [ColorPalette]
    @Published var recentColors: [CodableColor] = []
    @Published var savedProjects: [WallpaperProject] = []
    @Published var settings: AppSettings

    private let history = HistoryManager<WallpaperProject>()
    private var renderTask: Task<Void, Never>?
    private let persistence = PersistenceService.shared

    var canUndo: Bool { history.canUndo }
    var canRedo: Bool { history.canRedo }

    init(project: WallpaperProject = .blank()) {
        self.project = project
        self.customPalettes = PersistenceService.shared.loadCustomPalettes()
        self.settings = PersistenceService.shared.loadSettings()
        self.savedProjects = PersistenceService.shared.loadAllProjects()
        scheduleRender()
    }

    // MARK: - Editing entry point

    /// All mutations should go through this so undo history stays in sync.
    /// Usage: `vm.edit { $0.gradient.angleDegrees = 90 }`
    func edit(_ mutate: (inout WallpaperProject) -> Void) {
        history.recordSnapshot(project)
        mutate(&project)
        project.touch()
        scheduleRender()
    }

    /// For continuous gestures (sliders/drag), call this on every change
    /// without recording history, then call `commitContinuousEdit()` once
    /// the gesture ends so a single undo step is recorded for the whole
    /// drag instead of hundreds of intermediate ones.
    private var continuousEditBaseline: WallpaperProject?

    /// Call to mark the start of a continuous gesture (slider/color-picker
    /// drag) so the eventual `commitContinuousEdit()` records exactly one
    /// undo step for the whole gesture.
    func beginContinuousEdit() {
        if continuousEditBaseline == nil {
            continuousEditBaseline = project
        }
    }

    func applyContinuousEdit(_ mutate: (inout WallpaperProject) -> Void) {
        beginContinuousEdit()
        mutate(&project)
        project.touch()
        scheduleRender()
    }

    func commitContinuousEdit() {
        guard let baseline = continuousEditBaseline else { return }
        continuousEditBaseline = nil
        if baseline != project {
            history.recordSnapshot(baseline)
        }
    }

    // MARK: - Undo / Redo

    func undo() {
        guard let previous = history.undo(current: project) else { return }
        project = previous
        scheduleRender()
    }

    func redo() {
        guard let next = history.redo(current: project) else { return }
        project = next
        scheduleRender()
    }

    func resetToBlank() {
        edit { $0 = WallpaperProject.blank() }
        history.reset(with: project)
    }

    // MARK: - Presets

    func applyPreset(_ preset: WallpaperPreset) {
        edit { proj in
            let canvas = proj.canvasSize
            proj.gradient = preset.gradient
            proj.effects = preset.effects
            proj.name = preset.name
            proj.canvasSize = canvas
        }
    }

    func randomize() {
        edit { proj in
            proj.gradient = WallpaperGradient.randomized()
            let count = Int.random(in: 0...3)
            let candidateKinds: [EffectKind] = [.glow, .vignette, .noise, .blob, .radialGlow, .softLight]
            proj.effects = (0..<count).map { _ in
                var effect = WallpaperEffect.makeDefault(kind: candidateKinds.randomElement()!)
                effect.x = Double.random(in: 0.2...0.8)
                effect.y = Double.random(in: 0.2...0.8)
                return effect
            }
        }
    }

    // MARK: - Effects (layers)

    func addEffect(_ kind: EffectKind) {
        edit { proj in
            let effect = WallpaperEffect.makeDefault(kind: kind)
            proj.effects.append(effect)
            selectedEffectID = effect.id
        }
    }

    func duplicateSelectedEffect() {
        guard let id = selectedEffectID, let index = project.effects.firstIndex(where: { $0.id == id }) else { return }
        edit { proj in
            var copy = proj.effects[index]
            copy.id = UUID()
            proj.effects.insert(copy, at: index + 1)
            selectedEffectID = copy.id
        }
    }

    func deleteSelectedEffect() {
        guard let id = selectedEffectID else { return }
        edit { proj in
            proj.effects.removeAll { $0.id == id }
        }
        selectedEffectID = nil
    }

    func moveEffect(from offsets: IndexSet, to destination: Int) {
        edit { proj in
            proj.effects.move(fromOffsets: offsets, toOffset: destination)
        }
    }

    var selectedEffectBinding: Binding<WallpaperEffect>? {
        guard let id = selectedEffectID, let index = project.effects.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return Binding(
            get: { self.project.effects[index] },
            set: { newValue in
                self.project.effects[index] = newValue
                self.project.touch()
                self.scheduleRender()
            }
        )
    }

    // MARK: - Colors

    func registerRecentColor(_ color: CodableColor) {
        recentColors.removeAll { $0.hexString == color.hexString }
        recentColors.insert(color, at: 0)
        if recentColors.count > 16 {
            recentColors.removeLast()
        }
    }

    func saveCustomPalette(name: String, colors: [CodableColor]) {
        let palette = ColorPalette(name: name, colors: colors)
        customPalettes.append(palette)
        persistence.saveCustomPalettes(customPalettes)
    }

    func deleteCustomPalette(_ palette: ColorPalette) {
        customPalettes.removeAll { $0.id == palette.id }
        persistence.saveCustomPalettes(customPalettes)
    }

    // MARK: - Rendering

    func scheduleRender() {
        renderTask?.cancel()
        let snapshot = project
        renderTask = Task {
            // Debounce very rapid updates (e.g. slider drags) so we don't
            // saturate the render queue with stale frames.
            try? await Task.sleep(nanoseconds: 16_000_000)
            guard !Task.isCancelled else { return }
            await renderPreview(for: snapshot)
        }
    }

    private func renderPreview(for snapshot: WallpaperProject) async {
        isRendering = true
        let result: Result<CGImage, Error> = await Task.detached(priority: .userInitiated) {
            do {
                let image = try WallpaperRenderer.renderPreview(snapshot)
                return .success(image)
            } catch {
                return .failure(error)
            }
        }.value

        guard !Task.isCancelled else { return }
        isRendering = false
        switch result {
        case .success(let image):
            previewImage = image
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Persistence

    func saveProject() {
        do {
            project = try persistence.save(project)
            refreshSavedProjects()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshSavedProjects() {
        savedProjects = persistence.loadAllProjects()
    }

    func openProject(_ project: WallpaperProject) {
        self.project = project
        history.reset(with: project)
        scheduleRender()
    }

    func duplicateProject(_ project: WallpaperProject) {
        do {
            _ = try persistence.duplicate(project)
            refreshSavedProjects()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteProject(_ project: WallpaperProject) {
        persistence.delete(project)
        refreshSavedProjects()
    }

    func renameCurrentProject(to name: String) {
        edit { $0.name = name }
        saveProject()
    }

    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        persistence.saveSettings(newSettings)
    }
}
