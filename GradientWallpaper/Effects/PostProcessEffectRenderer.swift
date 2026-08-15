import CoreGraphics
import CoreImage
import UIKit

/// Draws full-canvas "post-process" style effects: noise/grain, glow,
/// blur, soft light, vignette, radial glow, color bloom, glass, liquid,
/// and aurora. These operate on the canvas as a whole rather than at a
/// fixed shape, though several still respect position/size for where
/// their effect is centered.
enum PostProcessEffectRenderer {

    static func draw(_ effect: WallpaperEffect, in context: CGContext, canvasSize: CGSize) {
        guard effect.isVisible else { return }

        switch effect.kind {
        case .noise, .grain:
            drawNoise(effect, context: context, canvasSize: canvasSize, fine: effect.kind == .grain)
        case .vignette:
            drawVignette(effect, context: context, canvasSize: canvasSize)
        case .glow, .radialGlow, .colorBloom:
            drawGlow(effect, context: context, canvasSize: canvasSize)
        case .softLight:
            drawSoftLight(effect, context: context, canvasSize: canvasSize)
        case .glass:
            drawGlass(effect, context: context, canvasSize: canvasSize)
        case .liquid:
            drawLiquid(effect, context: context, canvasSize: canvasSize)
        case .aurora:
            drawAurora(effect, context: context, canvasSize: canvasSize)
        case .blur:
            // Whole-canvas blur is applied as a final compositing pass by
            // WallpaperRenderer (it needs the already-drawn content), so
            // there is nothing to draw here directly.
            break
        default:
            break
        }
    }

    private static func drawNoise(_ effect: WallpaperEffect, context: CGContext, canvasSize: CGSize, fine: Bool) {
        guard let noiseImage = ImageEffects.noiseImage(
            size: canvasSize,
            intensity: effect.intensity,
            fine: fine
        ) else { return }
        context.saveGState()
        context.setBlendMode(effect.blendMode.cgBlendMode)
        context.setAlpha(CGFloat(effect.opacity))
        context.draw(noiseImage, in: CGRect(origin: .zero, size: canvasSize))
        context.restoreGState()
    }

    private static func drawVignette(_ effect: WallpaperEffect, context: CGContext, canvasSize: CGSize) {
        let colors = [
            CGColor(red: 0, green: 0, blue: 0, alpha: 0),
            CGColor(red: 0, green: 0, blue: 0, alpha: CGFloat(effect.intensity))
        ]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) else { return }
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let radius = max(canvasSize.width, canvasSize.height) * 0.75

        context.saveGState()
        context.setAlpha(CGFloat(effect.opacity))
        context.drawRadialGradient(
            gradient,
            startCenter: center, startRadius: radius * 0.4,
            endCenter: center, endRadius: radius,
            options: [.drawsAfterEndLocation]
        )
        context.restoreGState()
    }

    private static func drawGlow(_ effect: WallpaperEffect, context: CGContext, canvasSize: CGSize) {
        let center = CGPoint(x: canvasSize.width * CGFloat(effect.x), y: canvasSize.height * CGFloat(effect.y))
        let radius = max(canvasSize.width, canvasSize.height) * CGFloat(max(effect.width, effect.height))
        let colors = [effect.color.cgColor, effect.color.cgColor.copy(alpha: 0) ?? effect.color.cgColor]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) else { return }

        context.saveGState()
        context.setBlendMode(effect.blendMode.cgBlendMode)
        context.setAlpha(CGFloat(effect.opacity))
        context.drawRadialGradient(
            gradient,
            startCenter: center, startRadius: 0,
            endCenter: center, endRadius: radius,
            options: []
        )
        context.restoreGState()
    }

    private static func drawSoftLight(_ effect: WallpaperEffect, context: CGContext, canvasSize: CGSize) {
        context.saveGState()
        context.setBlendMode(.softLight)
        context.setAlpha(CGFloat(effect.opacity))
        context.setFillColor(effect.color.cgColor)
        context.fill(CGRect(origin: .zero, size: canvasSize))
        context.restoreGState()
    }

    private static func drawGlass(_ effect: WallpaperEffect, context: CGContext, canvasSize: CGSize) {
        let center = CGPoint(x: canvasSize.width * CGFloat(effect.x), y: canvasSize.height * CGFloat(effect.y))
        let w = canvasSize.width * CGFloat(effect.width)
        let h = canvasSize.height * CGFloat(effect.height)
        let rect = CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)

        context.saveGState()
        context.setBlendMode(effect.blendMode.cgBlendMode)
        context.setAlpha(CGFloat(effect.opacity))
        let path = CGPath(roundedRect: rect, cornerWidth: 40, cornerHeight: 40, transform: nil)
        context.addPath(path)
        context.clip()
        // Subtle white gradient sheen simulating a translucent glass panel.
        let colors = [CGColor(red: 1, green: 1, blue: 1, alpha: 0.5), CGColor(red: 1, green: 1, blue: 1, alpha: 0.05)]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1]) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: rect.minX, y: rect.minY),
                end: CGPoint(x: rect.maxX, y: rect.maxY),
                options: []
            )
        }
        context.restoreGState()
    }

    private static func drawLiquid(_ effect: WallpaperEffect, context: CGContext, canvasSize: CGSize) {
        // Several overlapping soft blobs, feathered, to emulate a liquid
        // metal / liquid glass sheen across the canvas.
        var generator = SeededGenerator(seed: UInt64(effect.id.hashValue.magnitude))
        for _ in 0..<4 {
            var blob = WallpaperEffect.makeDefault(kind: .blob)
            blob.x = Double.random(in: 0.2...0.8, using: &generator)
            blob.y = Double.random(in: 0.2...0.8, using: &generator)
            blob.width = Double.random(in: 0.25...0.5, using: &generator)
            blob.height = blob.width
            blob.color = effect.color
            blob.opacity = effect.opacity * 0.6
            blob.featherAmount = 0.9
            blob.blendMode = effect.blendMode
            ShapeEffectRenderer.draw(blob, in: context, canvasSize: canvasSize)
        }
    }

    private static func drawAurora(_ effect: WallpaperEffect, context: CGContext, canvasSize: CGSize) {
        // Several horizontal, feathered wave bands stacked to suggest
        // aurora borealis curtains of light.
        let bandCount = 3
        for i in 0..<bandCount {
            var wave = WallpaperEffect.makeDefault(kind: .wave)
            wave.x = 0.5
            wave.y = effect.y + Double(i) * 0.08 - 0.08
            wave.width = 1.1
            wave.height = effect.height
            wave.color = effect.color
            wave.opacity = effect.opacity * (1.0 - Double(i) * 0.25)
            wave.featherAmount = 0.85
            wave.blendMode = effect.blendMode
            ShapeEffectRenderer.draw(wave, in: context, canvasSize: canvasSize)
        }
    }
}
