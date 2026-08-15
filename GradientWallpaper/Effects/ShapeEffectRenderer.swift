import CoreGraphics
import UIKit

/// Draws the "shape" family of effects (circle, blob, wave, ring, square,
/// rounded rect, organic, line, curve) directly into the wallpaper canvas.
enum ShapeEffectRenderer {

    static func draw(_ effect: WallpaperEffect, in context: CGContext, canvasSize: CGSize) {
        guard effect.isVisible else { return }
        let center = CGPoint(x: canvasSize.width * CGFloat(effect.x), y: canvasSize.height * CGFloat(effect.y))
        let w = canvasSize.width * CGFloat(effect.width)
        let h = canvasSize.height * CGFloat(effect.height)
        let rect = CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)

        context.saveGState()
        context.setBlendMode(effect.blendMode.cgBlendMode)
        context.setAlpha(CGFloat(effect.opacity))
        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: CGFloat(effect.rotationDegrees) * .pi / 180)
        context.translateBy(x: -center.x, y: -center.y)

        let path = makePath(for: effect.kind, rect: rect, feather: effect.featherAmount, cornerRadius: CGFloat(effect.cornerRadius))

        if effect.featherAmount > 0.01 {
            // Feathering is approximated with a soft shadow-free blur pass:
            // draw the shape into an offscreen layer, then Gaussian blur it.
            drawFeathered(path: path, color: effect.color, feather: effect.featherAmount, rect: rect, context: context)
        } else {
            context.setFillColor(effect.color.cgColor)
            context.addPath(path)
            context.fillPath()
        }

        context.restoreGState()
    }

    private static func makePath(for kind: EffectKind, rect: CGRect, feather: Double, cornerRadius: CGFloat) -> CGPath {
        switch kind {
        case .circle:
            return CGPath(ellipseIn: rect, transform: nil)
        case .square:
            return CGPath(rect: rect, transform: nil)
        case .roundedRect:
            return CGPath(roundedRect: rect, cornerWidth: min(cornerRadius, rect.width / 2), cornerHeight: min(cornerRadius, rect.height / 2), transform: nil)
        case .ring:
            let outer = CGPath(ellipseIn: rect, transform: nil)
            let inset = rect.insetBy(dx: rect.width * 0.2, dy: rect.height * 0.2)
            let inner = CGPath(ellipseIn: inset, transform: nil)
            let combined = CGMutablePath()
            combined.addPath(outer)
            combined.addPath(inner)
            return combined
        case .blob:
            return blobPath(in: rect, seed: Int(rect.origin.x + rect.origin.y))
        case .organic:
            return blobPath(in: rect, seed: Int(rect.origin.x * 3 + rect.origin.y * 7))
        case .wave:
            return wavePath(in: rect)
        case .line:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        case .curve:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY),
                control1: CGPoint(x: rect.minX + rect.width * 0.7, y: rect.maxY),
                control2: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY)
            )
            return path
        default:
            return CGPath(ellipseIn: rect, transform: nil)
        }
    }

    /// A smooth, organic closed curve built from randomized-but-seeded
    /// radius perturbations around an ellipse, rendered with cubic beziers.
    private static func blobPath(in rect: CGRect, seed: Int) -> CGPath {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseRadius = min(rect.width, rect.height) / 2
        let pointCount = 8
        var generator = SeededGenerator(seed: UInt64(abs(seed) + 1))
        var points: [CGPoint] = []
        for i in 0..<pointCount {
            let angle = (CGFloat(i) / CGFloat(pointCount)) * 2 * .pi
            let variance = CGFloat.random(in: 0.75...1.25, using: &generator)
            let r = baseRadius * variance
            points.append(CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r))
        }
        let path = CGMutablePath()
        path.move(to: midpoint(points[points.count - 1], points[0]))
        for i in 0..<points.count {
            let current = points[i]
            let next = points[(i + 1) % points.count]
            let mid = midpoint(current, next)
            path.addQuadCurve(to: mid, control: current)
        }
        path.closeSubpath()
        return path
    }

    private static func wavePath(in rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        let waveCount = 3
        let step = rect.width / CGFloat(waveCount * 2)
        var x = rect.minX
        var goingUp = true
        for _ in 0..<(waveCount * 2) {
            let nextX = x + step
            let controlY = goingUp ? rect.minY : rect.maxY
            path.addQuadCurve(to: CGPoint(x: nextX, y: rect.midY), control: CGPoint(x: x + step / 2, y: controlY))
            x = nextX
            goingUp.toggle()
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY + 200))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY + 200))
        path.closeSubpath()
        return path
    }

    private static func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    private static func drawFeathered(path: CGPath, color: CodableColor, feather: Double, rect: CGRect, context: CGContext) {
        let padding: CGFloat = 200
        let layerRect = rect.insetBy(dx: -padding, dy: -padding)
        guard layerRect.width > 0, layerRect.height > 0,
              let layer = context.makeOffscreenLayer(size: layerRect.size) else {
            context.setFillColor(color.cgColor)
            context.addPath(path)
            context.fillPath()
            return
        }
        layer.context.saveGState()
        layer.context.translateBy(x: -layerRect.origin.x, y: -layerRect.origin.y)
        layer.context.setFillColor(color.cgColor)
        layer.context.addPath(path)
        layer.context.fillPath()
        layer.context.restoreGState()

        guard let cgImage = layer.context.makeImage() else { return }
        let blurRadius = CGFloat(feather) * 60
        let blurred = ImageEffects.gaussianBlur(cgImage, radius: blurRadius) ?? cgImage
        context.draw(blurred, in: layerRect)
    }
}

/// Deterministic pseudo-random generator so blob shapes stay stable across
/// re-renders of the same effect (important for live preview + export
/// producing identical results).
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
