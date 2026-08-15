import Foundation

/// The kind of visual layer that can be stacked on top of the base gradient.
enum EffectKind: String, Codable, CaseIterable, Identifiable {
    case circle, blob, wave, ring, square, roundedRect, organic, line, curve
    case noise, grain, glow, blur, softLight, vignette, radialGlow, colorBloom
    case glass, liquid, aurora

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .circle: return "Circle"
        case .blob: return "Blob"
        case .wave: return "Wave"
        case .ring: return "Ring"
        case .square: return "Square"
        case .roundedRect: return "Rounded Rect"
        case .organic: return "Organic Shape"
        case .line: return "Line"
        case .curve: return "Curve"
        case .noise: return "Noise"
        case .grain: return "Grain"
        case .glow: return "Glow"
        case .blur: return "Blur"
        case .softLight: return "Soft Light"
        case .vignette: return "Vignette"
        case .radialGlow: return "Radial Glow"
        case .colorBloom: return "Color Bloom"
        case .glass: return "Glass"
        case .liquid: return "Liquid"
        case .aurora: return "Aurora"
        }
    }

    var symbolName: String {
        switch self {
        case .circle: return "circle"
        case .blob: return "cloud"
        case .wave: return "water.waves"
        case .ring: return "circle.dashed"
        case .square: return "square"
        case .roundedRect: return "rectangle.roundedtop"
        case .organic: return "scribble"
        case .line: return "line.diagonal"
        case .curve: return "scribble.variable"
        case .noise: return "circle.grid.3x3.fill"
        case .grain: return "circle.grid.3x3"
        case .glow: return "sparkles"
        case .blur: return "drop.halffull"
        case .softLight: return "sun.min"
        case .vignette: return "vignette"
        case .radialGlow: return "sun.max"
        case .colorBloom: return "sparkle"
        case .glass: return "cube.transparent"
        case .liquid: return "drop"
        case .aurora: return "wind"
        }
    }

    /// Categorizes effects for the sidebar/palette grouping.
    var category: EffectCategory {
        switch self {
        case .circle, .blob, .wave, .ring, .square, .roundedRect, .organic, .line, .curve:
            return .shape
        default:
            return .postProcess
        }
    }
}

enum EffectCategory: String, CaseIterable {
    case shape = "Shapes"
    case postProcess = "Effects"
}

/// SwiftUI-compatible blend mode identifiers, mapped to CGBlendMode for
/// rendering and to SwiftUI's BlendMode for the live preview.
enum EffectBlendMode: String, Codable, CaseIterable, Identifiable {
    case normal, multiply, screen, overlay, softLight, hardLight
    case colorDodge, colorBurn, darken, lighten, difference, plusLighter

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .multiply: return "Multiply"
        case .screen: return "Screen"
        case .overlay: return "Overlay"
        case .softLight: return "Soft Light"
        case .hardLight: return "Hard Light"
        case .colorDodge: return "Color Dodge"
        case .colorBurn: return "Color Burn"
        case .darken: return "Darken"
        case .lighten: return "Lighten"
        case .difference: return "Difference"
        case .plusLighter: return "Plus Lighter"
        }
    }

    var cgBlendMode: CGBlendMode {
        switch self {
        case .normal: return .normal
        case .multiply: return .multiply
        case .screen: return .screen
        case .overlay: return .overlay
        case .softLight: return .softLight
        case .hardLight: return .hardLight
        case .colorDodge: return .colorDodge
        case .colorBurn: return .colorBurn
        case .darken: return .darken
        case .lighten: return .lighten
        case .difference: return .difference
        case .plusLighter: return .plusLighter
        }
    }
}

/// A single layered visual element: either a geometric shape or a
/// full-canvas post-process pass (grain, blur, vignette, etc).
struct WallpaperEffect: Codable, Hashable, Identifiable {
    var id = UUID()
    var kind: EffectKind
    var isVisible: Bool = true

    // Geometry (unit space 0...1, relative to canvas)
    var x: Double = 0.5
    var y: Double = 0.5
    var width: Double = 0.4
    var height: Double = 0.4
    var rotationDegrees: Double = 0
    var cornerRadius: Double = 24 // for rounded rect, in points at export resolution baseline

  var color: CodableColor = CodableColor.fromHex("FFFFFF")!
    var secondaryColor: CodableColor? = nil

    var opacity: Double = 0.6
    var blurRadius: Double = 40      // points, at a 1024pt baseline canvas
    var featherAmount: Double = 0.5  // 0...1, edge softness for shapes
    var intensity: Double = 0.7      // generic strength for noise/grain/aurora/liquid
    var blendMode: EffectBlendMode = .screen

    static func makeDefault(kind: EffectKind) -> WallpaperEffect {
        var effect = WallpaperEffect(kind: kind)
        switch kind {
        case .vignette:
            effect.opacity = 0.5
            effect.intensity = 0.6
            effect.blendMode = .normal
        case .noise, .grain:
            effect.opacity = 0.15
            effect.intensity = 0.4
            effect.blendMode = .overlay
        case .glow, .radialGlow, .colorBloom:
            effect.opacity = 0.55
            effect.blurRadius = 120
            effect.blendMode = .screen
        case .blur:
            effect.blurRadius = 60
            effect.opacity = 1.0
            effect.blendMode = .normal
        case .softLight:
            effect.blendMode = .softLight
            effect.opacity = 0.4
        case .glass:
            effect.opacity = 0.25
            effect.blurRadius = 30
            effect.blendMode = .overlay
        case .liquid, .aurora:
            effect.opacity = 0.5
            effect.blurRadius = 80
            effect.blendMode = .screen
        default:
            break
        }
        return effect
    }
}
