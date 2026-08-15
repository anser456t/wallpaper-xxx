import CoreGraphics
import UIKit

/// Composites a `WallpaperProject` into a final `CGImage` at an arbitrary
/// pixel size. This is the single rendering path used for both the live
/// preview (rendered small and cheap) and the final export (rendered at
/// full resolution), guaranteeing what-you-see-is-what-you-export.
enum WallpaperRenderer {

    enum RenderError: Error, LocalizedError {
        case invalidSize
        case contextCreationFailed
        case imageCreationFailed

        var errorDescription: String? {
            switch self {
            case .invalidSize: return "The requested canvas size is invalid."
            case .contextCreationFailed: return "Could not create a drawing surface for this resolution. Try a smaller size."
            case .imageCreationFailed: return "Rendering finished but the image could not be created."
            }
        }
    }

    static func render(_ project: WallpaperProject, pixelSize: CGSize) throws -> CGImage {
        guard pixelSize.width >= 1, pixelSize.height >= 1,
              pixelSize.width <= 8192, pixelSize.height <= 8192 else {
            throw RenderError.invalidSize
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(pixelSize.width),
            height: Int(pixelSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw RenderError.contextCreationFailed
        }

        // Base gradient
        GradientRenderer.draw(project.gradient, in: context, size: pixelSize)

        // Layered effects, bottom to top, in the order stored in the model.
        for effect in project.effects {
            switch effect.kind.category {
            case .shape:
                ShapeEffectRenderer.draw(effect, in: context, canvasSize: pixelSize)
            case .postProcess:
                PostProcessEffectRenderer.draw(effect, in: context, canvasSize: pixelSize)
            }
        }

        guard var image = context.makeImage() else {
            throw RenderError.imageCreationFailed
        }

        // Whole-canvas blur effects are applied last, on the fully
        // composited image, since they need to blur everything beneath
        // them rather than just their own (nonexistent) shape.
        let blurEffects = project.effects.filter { $0.kind == .blur && $0.isVisible }
        for blurEffect in blurEffects {
            let scaledRadius = CGFloat(blurEffect.blurRadius) * (pixelSize.width / 1024.0)
            if let blurred = ImageEffects.blurWholeCanvas(image, radius: scaledRadius) {
                image = blurred
            }
        }

        return image
    }

    /// Convenience for SwiftUI preview rendering at a throttled preview
    /// resolution so scrubbing controls stays smooth.
    static func renderPreview(_ project: WallpaperProject, maxDimension: CGFloat = 900) throws -> CGImage {
        let aspect = project.canvasSize.aspectRatio
        let size: CGSize
        if aspect >= 1 {
            size = CGSize(width: maxDimension, height: maxDimension / aspect)
        } else {
            size = CGSize(width: maxDimension * aspect, height: maxDimension)
        }
        return try render(project, pixelSize: size)
    }

    static func uiImage(from cgImage: CGImage) -> UIImage {
        UIImage(cgImage: cgImage)
    }
}
