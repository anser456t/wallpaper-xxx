import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import UIKit

/// Shared Core Image helpers for Gaussian blur and procedural noise/grain,
/// used by both the shape feathering code and the full-canvas blur pass.
enum ImageEffects {

    private static let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    static func gaussianBlur(_ image: CGImage, radius: CGFloat) -> CGImage? {
        guard radius > 0.01 else { return image }
        let ciImage = CIImage(cgImage: image)
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = ciImage
        filter.radius = Float(radius)
        guard let output = filter.outputImage else { return nil }
        // Gaussian blur expands the extent; crop back to the original rect
        // so the result composites at the expected size/position.
        let cropped = output.cropped(to: ciImage.extent)
        return ciContext.createCGImage(cropped, from: cropped.extent)
    }

    static func blurWholeCanvas(_ image: CGImage, radius: CGFloat) -> CGImage? {
        guard radius > 0.01 else { return image }
        let ciImage = CIImage(cgImage: image)
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = ciImage
        filter.radius = Float(radius)
        guard let output = filter.outputImage else { return nil }
        let cropped = output.cropped(to: ciImage.extent)
        return ciContext.createCGImage(cropped, from: ciImage.extent)
    }

    /// Generates a tileable procedural noise/grain texture using Core
    /// Image's random noise generator, filtered to a chosen fineness.
    static func noiseImage(size: CGSize, intensity: Double, fine: Bool) -> CGImage? {
        let filter = CIFilter.randomGenerator()
        guard var output = filter.outputImage else { return nil }
        let extent = CGRect(origin: .zero, size: size)
        output = output.cropped(to: extent)

        // Convert to monochrome so it blends as neutral grain rather than
        // colored static, then scale contrast via intensity.
        let mono = CIFilter.colorControls()
        mono.inputImage = output
        mono.saturation = 0
        mono.contrast = fine ? 1.4 : 1.1
        mono.brightness = 0

        guard let monoOutput = mono.outputImage else { return nil }
        return ciContext.createCGImage(monoOutput, from: extent)
    }
}

/// A small helper representing an offscreen CGContext + its pixel size,
/// used for feathering shapes without disturbing the main canvas context.
struct OffscreenLayer {
    let context: CGContext
    let size: CGSize
}

extension CGContext {
    func makeOffscreenLayer(size: CGSize) -> OffscreenLayer? {
        guard size.width > 0, size.height > 0 else { return nil }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: max(Int(size.width), 1),
            height: max(Int(size.height), 1),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        return OffscreenLayer(context: ctx, size: size)
    }
}
