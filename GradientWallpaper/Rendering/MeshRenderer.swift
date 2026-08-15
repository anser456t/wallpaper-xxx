import CoreGraphics
import UIKit

/// Draws a smooth mesh gradient from an arbitrary set of colored points.
/// Since Core Graphics has no public mesh-shading API available across all
/// supported OS versions, this uses inverse-distance-weighted color
/// blending sampled onto a coarse grid of small filled rects, which
/// produces a smooth, blended result at interactive speed.
enum MeshRenderer {

    static func draw(_ gradient: WallpaperGradient, context: CGContext, size: CGSize) {
        let points = gradient.meshPoints
        guard !points.isEmpty else { return }

        // Grid resolution: fine enough to look smooth, coarse enough to
        // stay fast even during live-preview scrubbing.
        let cols = 48
        let rows = Int((CGFloat(cols) * size.height / max(size.width, 1)).rounded())
        let cellW = size.width / CGFloat(cols)
        let cellH = size.height / CGFloat(max(rows, 1))

        let samples: [(x: Double, y: Double, r: Double, g: Double, b: Double)] = points.map {
            (Double($0.x), Double($0.y), $0.color.red, $0.color.green, $0.color.blue)
        }

        context.saveGState()
        for row in 0...max(rows, 1) {
            for col in 0...cols {
                let px = Double(col) / Double(cols)
                let py = Double(row) / Double(max(rows, 1))
                let color = inverseDistanceColor(x: px, y: py, samples: samples)
                context.setFillColor(red: CGFloat(color.0), green: CGFloat(color.1), blue: CGFloat(color.2), alpha: 1)
                let rect = CGRect(
                    x: CGFloat(col) * cellW - cellW / 2,
                    y: CGFloat(row) * cellH - cellH / 2,
                    width: cellW * 1.5,
                    height: cellH * 1.5
                )
                context.fill(rect)
            }
        }
        context.restoreGState()
    }

    private static func inverseDistanceColor(
        x: Double, y: Double,
        samples: [(x: Double, y: Double, r: Double, g: Double, b: Double)]
    ) -> (Double, Double, Double) {
        var weightSum = 0.0
        var r = 0.0, g = 0.0, b = 0.0
        let power = 3.0
        for s in samples {
            let dx = x - s.x, dy = y - s.y
            let distSq = dx * dx + dy * dy
            if distSq < 0.000001 {
                return (s.r, s.g, s.b)
            }
            let weight = 1.0 / pow(distSq, power / 2)
            weightSum += weight
            r += s.r * weight
            g += s.g * weight
            b += s.b * weight
        }
        guard weightSum > 0 else { return (1, 1, 1) }
        return (r / weightSum, g / weightSum, b / weightSum)
    }
}
