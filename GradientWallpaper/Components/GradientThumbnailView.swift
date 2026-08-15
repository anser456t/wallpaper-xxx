import SwiftUI

/// A fast, native-SwiftUI approximation of a `WallpaperGradient` used for
/// preset grids and palette chips where rendering the full Core Graphics
/// pipeline for every cell would be wasteful. The real renderer is always
/// used for the main preview and export.
struct GradientThumbnailView: View {
    let gradient: WallpaperGradient

    var body: some View {
        let colors = gradient.stops.sorted { $0.location < $1.location }.map { $0.color.color }
        let locations = gradient.stops.sorted { $0.location < $1.location }.map { $0.location }
        let stops = zip(colors, locations).map { Gradient.Stop(color: $0, location: CGFloat($1)) }
        let swiftGradient = Gradient(stops: stops.isEmpty ? [Gradient.Stop(color: .gray, location: 0)] : stops)

        Group {
            switch gradient.kind {
            case .linear:
                LinearGradient(
                    gradient: swiftGradient,
                    startPoint: unitPoint(angle: gradient.angleDegrees, atStart: true),
                    endPoint: unitPoint(angle: gradient.angleDegrees, atStart: false)
                )
            case .radial, .reflected, .diamond:
                RadialGradient(
                    gradient: swiftGradient,
                    center: UnitPoint(x: gradient.centerX, y: gradient.centerY),
                    startRadius: 0,
                    endRadius: 140
                )
            case .angular:
                AngularGradient(
                    gradient: swiftGradient,
                    center: UnitPoint(x: gradient.centerX, y: gradient.centerY)
                )
            case .mesh:
                meshApproximation
            }
        }
    }

    private var meshApproximation: some View {
        ZStack {
            Color(gradient.meshPoints.first?.color.color ?? .gray)
            ForEach(gradient.meshPoints) { point in
                RadialGradient(
                    colors: [point.color.color, point.color.color.opacity(0)],
                    center: UnitPoint(x: point.x, y: point.y),
                    startRadius: 0,
                    endRadius: 160
                )
            }
        }
    }

    private func unitPoint(angle: Double, atStart: Bool) -> UnitPoint {
        let radians = angle * .pi / 180
        let dx = cos(radians) * 0.5
        let dy = sin(radians) * 0.5
        return atStart
            ? UnitPoint(x: 0.5 - dx, y: 0.5 - dy)
            : UnitPoint(x: 0.5 + dx, y: 0.5 + dy)
    }
}
