import UIKit
import CoreGraphics
import UniformTypeIdentifiers

/// Handles turning a `WallpaperProject` into an exported image file on
/// disk, ready for the share sheet or a direct Photos save.
final class ExportService {
    static let shared = ExportService()

    enum ExportError: Error, LocalizedError {
        case renderFailed(String)
        case encodingFailed
        case writeFailed(String)
        case resolutionTooLarge

        var errorDescription: String? {
            switch self {
            case .renderFailed(let reason): return "Rendering failed: \(reason)"
            case .encodingFailed: return "Couldn't encode the image for export."
            case .writeFailed(let reason): return "Couldn't write the file: \(reason)"
            case .resolutionTooLarge: return "That resolution is too large for this device to export reliably. Try something under 8000×8000."
            }
        }
    }

    /// Renders the project at the requested resolution and writes it to a
    /// temporary file, returning the file URL for sharing/saving.
    func export(
        project: WallpaperProject,
        resolution: CGSize,
        format: ExportFormat,
        jpegQuality: Double = 0.9
    ) throws -> URL {
        guard resolution.width <= 8192, resolution.height <= 8192 else {
            throw ExportError.resolutionTooLarge
        }

        let cgImage: CGImage
        do {
            cgImage = try WallpaperRenderer.render(project, pixelSize: resolution)
        } catch {
            throw ExportError.renderFailed(error.localizedDescription)
        }

        let uiImage = UIImage(cgImage: cgImage)
        let data: Data?
        switch format {
        case .png:
            data = uiImage.pngData()
        case .jpeg:
            data = uiImage.jpegData(compressionQuality: CGFloat(jpegQuality))
        }

        guard let fileData = data else {
            throw ExportError.encodingFailed
        }

        let safeName = project.name.isEmpty ? "Wallpaper" : project.name
        let sanitized = safeName.replacingOccurrences(of: "/", with: "-")
        let fileName = "\(sanitized)-\(Int(resolution.width))x\(Int(resolution.height)).\(format.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try fileData.write(to: tempURL, options: .atomic)
        } catch {
            throw ExportError.writeFailed(error.localizedDescription)
        }

        return tempURL
    }

    /// Saves the rendered image directly to the Photos library.
    func saveToPhotos(project: WallpaperProject, resolution: CGSize, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let cgImage = try WallpaperRenderer.render(project, pixelSize: resolution)
            let uiImage = UIImage(cgImage: cgImage)
            PhotoLibrarySaver.save(uiImage, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }
}
