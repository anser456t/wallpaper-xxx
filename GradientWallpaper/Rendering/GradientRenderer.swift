import CoreGraphics
import UIKit

/// Renders a `WallpaperGradient` into a CGContext. Every gradient kind is
/// implemented with real Core Graphics drawing (no placeholder colors), so
/// the same code path powers both the live preview and the final export.
enum GradientRenderer {

    static func draw(_ gradient: WallpaperGradient, in context: CGContext, size: CGSize) {
        context.saveGState()
        defer { context.restoreGState() }

        switch gradient.kind {
        case .linear:
            drawLinear(gradient, context: context, size: size)
        case .radial:
            drawRadial(gradient, context: context, size: size, reflected: false)
        case .reflected:
            drawRadial(gradient, context: context, size: size, reflected: true)
        case .angular:
            drawAngular(gradient, context: context, size: size)
        case .diamond:
            drawDiamond(gradient, context: context, size: size)
        case .mesh:
            MeshRenderer.draw(gradient, context: context, size: size)
        }
    }

    private static func cgGradient(from stops: [GradientStop]) -> CGGradient? {
        let sorted = stops.sorted { $0.location < $1.location }
        let colors = sorted.map { $0.color.cgColor } as CFArray
        let locations = sorted.map { CGFloat($0.location) }
        return CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: locations
        )
    }

    private static func drawLinear(_ gradient: WallpaperGradient, context: CGContext, size: CGSize) {
        guard let cg = cgGradient(from: gradient.stops) else { return }
        let angle = gradient.angleDegrees * .pi / 180
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        // Diagonal length ensures the ramp always covers the full canvas
        // regardless of angle, then `spread` scales it in from there.
        let diagonal = sqrt(size.width * size.width + size.height * size.height)
        let length = diagonal * CGFloat(gradient.spread)
        let dx = cos(angle) * length / 2
        let dy = sin(angle) * length / 2
        let start = CGPoint(x: center.x - dx, y: center.y - dy)
        let end = CGPoint(x: center.x + dx, y: center.y + dy)
        context.drawLinearGradient(
            cg, start: start, end: end,
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
    }

    private static func drawRadial(_ gradient: WallpaperGradient, context: CGContext, size: CGSize, reflected: Bool) {
        guard let cg = cgGradient(from: reflected ? reflectedStops(gradient.stops) : gradient.stops) else { return }
        let shortSide = min(size.width, size.height)
        let center = CGPoint(x: size.width * CGFloat(gradient.centerX), y: size.height * CGFloat(gradient.centerY))
        let radius = shortSide * CGFloat(gradient.radius)

        context.saveGState()
        // Aspect ratio stretches the radial into an ellipse by scaling the
        // context around the center before drawing a circular gradient.
        context.translateBy(x: center.x, y: center.y)
        context.scaleBy(x: CGFloat(gradient.aspectRatio), y: 1.0)
        context.translateBy(x: -center.x, y: -center.y)

        context.drawRadialGradient(
            cg,
            startCenter: center, startRadius: 0,
            endCenter: center, endRadius: radius,
            options: [.drawsAfterEndLocation]
        )
        context.restoreGState()
    }

    /// Mirrors the stop ramp out-and-back so the gradient reflects at its
    /// midpoint, producing a "reflected" gradient from a radial base.
    private static func reflectedStops(_ stops: [GradientStop]) -> [GradientStop] {
        let sorted = stops.sorted { $0.location < $1.location }
        var result = sorted.map { GradientStop(color: $0.color, location: $0.location / 2) }
        result += sorted.reversed().map { GradientStop(color: $0.color, location: 1 - ($0.location / 2)) }
        return result
    }

    private static func drawAngular(_ gradient: WallpaperGradient, context: CGContext, size: CGSize) {
        // Core Graphics has no native conic gradient API, so we approximate
        // by drawing many thin angular wedges sampled from the color ramp.
        let center = CGPoint(x: size.width * CGFloat(gradient.centerX), y: size.height * CGFloat(gradient.centerY))
        let maxRadius = sqrt(size.width * size.width + size.height * size.height)
        let segments = 360
        let startAngle = gradient.startAngleDegrees * .pi / 180
        let rotation = gradient.rotationDegrees * .pi / 180

        context.saveGState()
        context.translateBy(x: center.x, y: center.y)
        for i in 0..<segments {
            let t0 = Double(i) / Double(segments)
            let t1 = Double(i + 1) / Double(segments)
            let a0 = startAngle + rotation + CGFloat(t0) * 2 * .pi
            let a1 = startAngle + rotation + CGFloat(t1) * 2 * .pi
            let color = gradient.colorAt(location: (t0 + t1) / 2)
            context.setFillColor(color.cgColor)
            let path = CGMutablePath()
            path.move(to: .zero)
            path.addArc(center: .zero, radius: maxRadius, startAngle: a0, endAngle: a1, clockwise: false)
            path.closeSubpath()
            context.addPath(path)
            context.fillPath()
        }
        context.restoreGState()
    }

    private static func drawDiamond(_ gradient: WallpaperGradient, context: CGContext, size: CGSize) {
        // Approximate a diamond gradient by evaluating Chebyshev-rotated
        // ("taxicab" at 45°) distance per scanline band using a mask stack:
        // draw concentric diamond rings from the outside in.
        let center = CGPoint(x: size.width * CGFloat(gradient.centerX), y: size.height * CGFloat(gradient.centerY))
        let maxExtent = max(size.width, size.height) * CGFloat(gradient.radius)
        let rings = 128
        context.saveGState()
        for i in stride(from: rings, through: 0, by: -1) {
            let t = Double(i) / Double(rings)
            let extent = maxExtent * CGFloat(t)
            let color = gradient.colorAt(location: 1 - t)
            context.setFillColor(color.cgColor)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: center.x, y: center.y - extent))
            path.addLine(to: CGPoint(x: center.x + extent, y: center.y))
            path.addLine(to: CGPoint(x: center.x, y: center.y + extent))
            path.addLine(to: CGPoint(x: center.x - extent, y: center.y))
            path.closeSubpath()
            context.addPath(path)
            context.fillPath()
        }
        context.restoreGState()
    }
}
