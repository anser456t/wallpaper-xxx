import SwiftUI

@main
struct GradientWallpaperApp: App {
    @StateObject private var viewModel = WallpaperEditorViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .preferredColorScheme(colorScheme(for: viewModel.settings.preferredColorScheme))
        }
    }

    private func colorScheme(for raw: String) -> ColorScheme? {
        switch raw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
