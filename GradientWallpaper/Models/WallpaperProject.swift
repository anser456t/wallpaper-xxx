import Foundation

/// The complete, persistable description of one wallpaper design.
/// This is the single source of truth the renderer consumes and the
/// document that gets saved to disk.
struct WallpaperProject: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    var gradient: WallpaperGradient = WallpaperGradient()
    var effects: [WallpaperEffect] = []
    var canvasSize: CanvasSize = .ipadPortrait
    var backgroundIsDark: Bool = false

    static func blank(name: String = "Untitled Wallpaper") -> WallpaperProject {
        WallpaperProject(name: name)
    }

    static func from(preset: WallpaperPreset) -> WallpaperProject {
        WallpaperProject(
            name: preset.name,
            gradient: preset.gradient,
            effects: preset.effects,
            canvasSize: .ipadPortrait
        )
    }

    mutating func touch() {
        modifiedAt = Date()
    }
}
