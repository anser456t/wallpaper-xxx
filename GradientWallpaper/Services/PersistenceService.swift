import Foundation

/// Handles reading/writing wallpaper projects, custom palettes, and app
/// settings to the app's Documents directory as JSON. Using plain JSON
/// files (rather than Core Data) keeps the model layer simple and makes
/// projects easy to inspect, migrate, or sync later.
final class PersistenceService {
    static let shared = PersistenceService()

    private let fileManager = FileManager.default

    private lazy var documentsURL: URL = {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()

    private lazy var projectsDirectory: URL = {
        let url = documentsURL.appendingPathComponent("Projects", isDirectory: true)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    private var palettesURL: URL {
        documentsURL.appendingPathComponent("custom_palettes.json")
    }

    private var settingsURL: URL {
        documentsURL.appendingPathComponent("settings.json")
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Projects

    private func fileURL(for project: WallpaperProject) -> URL {
        projectsDirectory.appendingPathComponent("\(project.id.uuidString).json")
    }

    enum PersistenceError: Error, LocalizedError {
        case saveFailed(String)
        case loadFailed(String)

        var errorDescription: String? {
            switch self {
            case .saveFailed(let reason): return "Couldn't save: \(reason)"
            case .loadFailed(let reason): return "Couldn't load: \(reason)"
            }
        }
    }

    @discardableResult
    func save(_ project: WallpaperProject) throws -> WallpaperProject {
        var project = project
        project.touch()
        do {
            let data = try encoder.encode(project)
            try data.write(to: fileURL(for: project), options: .atomic)
            return project
        } catch {
            throw PersistenceError.saveFailed(error.localizedDescription)
        }
    }

    func delete(_ project: WallpaperProject) {
        try? fileManager.removeItem(at: fileURL(for: project))
    }

    func duplicate(_ project: WallpaperProject) throws -> WallpaperProject {
        var copy = project
        copy.id = UUID()
        copy.name = project.name + " Copy"
        copy.createdAt = Date()
        copy.modifiedAt = Date()
        return try save(copy)
    }

    func loadAllProjects() -> [WallpaperProject] {
        guard let files = try? fileManager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        let projects: [WallpaperProject] = files.compactMap { url in
            guard url.pathExtension == "json", let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(WallpaperProject.self, from: data)
        }
        return projects.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    // MARK: - Custom Palettes

    func loadCustomPalettes() -> [ColorPalette] {
        guard let data = try? Data(contentsOf: palettesURL) else { return [] }
        return (try? decoder.decode([ColorPalette].self, from: data)) ?? []
    }

    func saveCustomPalettes(_ palettes: [ColorPalette]) {
        guard let data = try? encoder.encode(palettes) else { return }
        try? data.write(to: palettesURL, options: .atomic)
    }

    // MARK: - Settings

    func loadSettings() -> AppSettings {
        guard let data = try? Data(contentsOf: settingsURL),
              let settings = try? decoder.decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        try? data.write(to: settingsURL, options: .atomic)
    }
}

/// Persisted app-wide preferences.
struct AppSettings: Codable, Equatable {
    var preferredColorScheme: String = "system" // "system" | "light" | "dark"
    var defaultExportFormat: ExportFormat = .png
    var defaultJPEGQuality: Double = 0.9
    var defaultCanvasSizeName: String = CanvasSize.ipadPortrait.name
}
