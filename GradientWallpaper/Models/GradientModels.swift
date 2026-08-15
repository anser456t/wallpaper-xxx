import Foundation
import CoreGraphics

/// The visual style used to interpolate between color stops.
enum GradientKind: String, Codable, CaseIterable, Identifiable {
    case linear
    case radial
    case angular
    case diamond
    case reflected
    case mesh

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .linear: return "Linear"
        case .radial: return "Radial"
        case .angular: return "Angular"
        case .diamond: return "Diamond"
        case .reflected: return "Reflected"
        case .mesh: return "Mesh"
        }
    }

    var symbolName: String {
        switch self {
        case .linear: return "line.diagonal"
        case .radial: return "circle.circle"
        case .angular: return "angle"
        case .diamond: return "diamond"
        case .reflected: return "arrow.left.and.right"
        case .mesh: return "square.grid.3x3"
        }
    }
}

/// One color stop in a gradient ramp. `location` is normalized 0...1.
struct GradientStop: Codable, Hashable, Identifiable {
    var id = UUID()
    var color: CodableColor
    var location: Double

    init(id: UUID = UUID(), color: CodableColor, location: Double) {
        self.id = id
        self.color = color
        self.location = location
    }
}

/// A single point in a mesh gradient, positioned in unit space (0...1).
struct MeshPoint: Codable, Hashable, Identifiable {
    var id = UUID()
    var x: Double
    var y: Double
    var color: CodableColor
}

/// The complete description of a gradient: its type, color stops, and all
/// geometry parameters needed for every supported gradient kind.
struct WallpaperGradient: Codable, Hashable {
    var kind: GradientKind = .linear
    var stops: [GradientStop] = [
        GradientStop(color: CodableColor.fromHex("FF6B6B")!, location: 0.0),
        GradientStop(color: CodableColor.fromHex("4ECDC4")!, location: 1.0)
    ]

    // Linear
    var angleDegrees: Double = 45
    var spread: Double = 1.0 // 0...2, scales how far the ramp travels

    // Radial / Angular / Diamond / Reflected shared geometry
    var centerX: Double = 0.5
    var centerY: Double = 0.5
    var radius: Double = 0.75          // normalized to the shorter canvas dimension
    var aspectRatio: Double = 1.0      // stretches the radial ellipse
    var startAngleDegrees: Double = 0  // angular gradient start
    var rotationDegrees: Double = 0    // angular gradient rotation

    // Mesh
    var meshPoints: [MeshPoint] = [
        MeshPoint(x: 0.15, y: 0.15, color: CodableColor.fromHex("FF6B6B")!),
        MeshPoint(x: 0.85, y: 0.15, color: CodableColor.fromHex("4ECDC4")!),
        MeshPoint(x: 0.15, y: 0.85, color: CodableColor.fromHex("6B5BFF")!),
        MeshPoint(x: 0.85, y: 0.85, color: CodableColor.fromHex("FFD93D")!)
    ]

    mutating func sortStops() {
        stops.sort { $0.location < $1.location }
    }

    mutating func addStop(at location: Double) {
        let color = colorAt(location: location)
        stops.append(GradientStop(color: color, location: location))
        sortStops()
    }

    mutating func removeStop(id: UUID) {
        guard stops.count > 2 else { return }
        stops.removeAll { $0.id == id }
    }

    /// Interpolated color at a normalized location, used for previews and
    /// when inserting a new stop between two existing ones.
    func colorAt(location: Double) -> CodableColor {
        let sorted = stops.sorted { $0.location < $1.location }
        guard let first = sorted.first, let last = sorted.last else { return .white }
        if location <= first.location { return first.color }
        if location >= last.location { return last.color }
        for i in 0..<(sorted.count - 1) {
            let a = sorted[i], b = sorted[i + 1]
            if location >= a.location && location <= b.location {
                let range = b.location - a.location
                let t = range > 0 ? (location - a.location) / range : 0
                return CodableColor(
                    red: a.color.red + (b.color.red - a.color.red) * t,
                    green: a.color.green + (b.color.green - a.color.green) * t,
                    blue: a.color.blue + (b.color.blue - a.color.blue) * t,
                    alpha: a.color.alpha + (b.color.alpha - a.color.alpha) * t
                )
            }
        }
        return last.color
    }

    static func randomized() -> WallpaperGradient {
        var g = WallpaperGradient()
        g.kind = GradientKind.allCases.filter { $0 != .mesh }.randomElement() ?? .linear
        let base = ColorPalette.presets.randomElement()?.colors ?? [.white, .black]
        let count = Int.random(in: 2...min(4, max(2, base.count)))
        g.stops = (0..<count).map { i in
            GradientStop(color: base[i % base.count], location: Double(i) / Double(max(count - 1, 1)))
        }
        g.angleDegrees = Double.random(in: 0...360)
        g.centerX = Double.random(in: 0.3...0.7)
        g.centerY = Double.random(in: 0.3...0.7)
        g.radius = Double.random(in: 0.5...1.0)
        return g
    }
}
