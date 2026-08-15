import Foundation

enum PresetCategory: String, CaseIterable, Identifiable, Codable {
    case minimal = "Minimal"
    case abstract = "Abstract"
    case amoled = "AMOLED"
    case neon = "Neon"
    case pastel = "Pastel"
    case luxury = "Luxury"
    case nature = "Nature"
    case aurora = "Aurora"
    case sunset = "Sunset"
    case space = "Space"
    case glass = "Glass"
    case liquid = "Liquid"
    case mesh = "Mesh"
    case dark = "Dark"
    case light = "Light"

    var id: String { rawValue }
}

/// A fully-formed wallpaper starting point. Selecting one loads a
/// `WallpaperProject`, which remains freely editable afterward.
struct WallpaperPreset: Identifiable, Hashable {
    var id = UUID()
    var name: String
    var category: PresetCategory
    var gradient: WallpaperGradient
    var effects: [WallpaperEffect] = []

    private static func stops(_ hexes: [String], locations: [Double]? = nil) -> [GradientStop] {
        let locs = locations ?? hexes.enumerated().map { i, _ in
            hexes.count > 1 ? Double(i) / Double(hexes.count - 1) : 0
        }
        return zip(hexes, locs).map { hex, loc in
            GradientStop(color: CodableColor.fromHex(hex) ?? .white, location: loc)
        }
    }

    static let all: [WallpaperPreset] = [
        // MARK: Minimal
        WallpaperPreset(
            name: "Soft Fade",
            category: .minimal,
            gradient: {
                var g = WallpaperGradient(); g.kind = .linear
                g.stops = stops(["F5F7FA", "C3CFE2"]); g.angleDegrees = 120
                return g
            }()
        ),
        WallpaperPreset(
            name: "Paper White",
            category: .minimal,
            gradient: {
                var g = WallpaperGradient(); g.kind = .radial
                g.stops = stops(["FFFFFF", "E8E8E8"]); g.radius = 1.2
                return g
            }()
        ),

        // MARK: Abstract
        WallpaperPreset(
            name: "Color Clash",
            category: .abstract,
            gradient: {
                var g = WallpaperGradient(); g.kind = .angular
                g.stops = stops(["FF6B6B", "FFD93D", "6BCB77", "4D96FF", "FF6B6B"])
                return g
            }(),
            effects: [
                {
                    var e = WallpaperEffect.makeDefault(kind: .blob)
                    e.x = 0.3; e.y = 0.4; e.width = 0.5; e.height = 0.5
                    e.color = CodableColor.fromHex("FFFFFF")!; e.opacity = 0.15
                    return e
                }()
            ]
        ),
        WallpaperPreset(
            name: "Geo Bloom",
            category: .abstract,
            gradient: {
                var g = WallpaperGradient(); g.kind = .diamond
                g.stops = stops(["1A2980", "26D0CE"])
                return g
            }(),
            effects: [
                {
                    var e = WallpaperEffect.makeDefault(kind: .roundedRect)
                    e.x = 0.5; e.y = 0.5; e.width = 0.6; e.height = 0.3
                    e.rotationDegrees = 30; e.color = .white; e.opacity = 0.12
                    return e
                }()
            ]
        ),

        // MARK: AMOLED
        WallpaperPreset(
            name: "True Black",
            category: .amoled,
            gradient: {
                var g = WallpaperGradient(); g.kind = .radial
                g.stops = stops(["0A0A0A", "000000"]); g.radius = 1.4
                return g
            }(),
            effects: [
                {
                    var e = WallpaperEffect.makeDefault(kind: .glow)
                    e.x = 0.5; e.y = 0.3; e.width = 0.3; e.height = 0.3
                    e.color = CodableColor.fromHex("6B5BFF")!; e.opacity = 0.35
                    return e
                }()
            ]
        ),
        WallpaperPreset(
            name: "Neon Edge",
            category: .amoled,
            gradient: {
                var g = WallpaperGradient(); g.kind = .linear
                g.stops = stops(["000000", "000000"]); g.angleDegrees = 90
                return g
            }(),
            effects: [
                {
                    var e = WallpaperEffect.makeDefault(kind: .ring)
                    e.x = 0.5; e.y = 0.85; e.width = 0.9; e.height = 0.5
                    e.color = CodableColor.fromHex("FF00E5")!; e.opacity = 0.5
                    e.blurRadius = 90
                    return e
                }()
            ]
        ),

        // MARK: Neon
        WallpaperPreset(
            name: "Vaporwave",
            category: .neon,
            gradient: {
                var g = WallpaperGradient(); g.kind = .linear
                g.stops = stops(["FF00E5", "00FFF0"]); g.angleDegrees = 60
                return g
            }()
        ),
        WallpaperPreset(
            name: "Electric Night",
            category: .neon,
            gradient: {
                var g = WallpaperGradient(); g.kind = .radial
                g.stops = stops(["0D0221", "FF2079"]); g.radius = 1.1
                return g
            }(),
            effects: [
                {
                    var e = WallpaperEffect.makeDefault(kind: .colorBloom)
                    e.x = 0.7; e.y = 0.25; e.width = 0.4; e.height = 0.4
                    e.color = CodableColor.fromHex("00F0FF")!
                    return e
                }()
            ]
        ),

        // MARK: Pastel
        WallpaperPreset(
            name: "Cotton Sky",
            category: .pastel,
            gradient: {
                var g = WallpaperGradient(); g.kind = .linear
                g.stops = stops(["FFC6E5", "C6E5FF"]); g.angleDegrees = 100
                return g
            }()
        ),
        WallpaperPreset(
            name: "Peach Fuzz",
            category: .pastel,
            gradient: {
                var g = WallpaperGradient(); g.kind = .radial
                g.stops = stops(["FFE8D6", "FFD1DC"])
                return g
            }()
        ),

        // MARK: Luxury
        WallpaperPreset(
            name: "Gold Silk",
            category: .luxury,
            gradient: {
                var g = WallpaperGradient(); g.kind = .linear
                g.stops = stops(["1A1A1A", "5C4A1F", "D4AF37"]); g.angleDegrees = 135
                return g
            }()
        ),
        WallpaperPreset(
            name: "Emerald Velvet",
            category: .luxury,
            gradient: {
                var g = WallpaperGradient(); g.kind = .radial
                g.stops = stops(["0B3D02", "062E03"]); g.radius = 1.3
                return g
            }(),
            effects: [
                {
                    var e = WallpaperEffect.makeDefault(kind: .glow)
                    e.color = CodableColor.fromHex("D4AF37")!; e.opacity = 0.2
                    return e
                }()
            ]
        ),

        // MARK: Nature
        WallpaperPreset(
            name: "Forest Mist",
            category: .nature,
            gradient: {
                var g = WallpaperGradient(); g.kind = .linear
                g.stops = stops(["0B3D02", "76B947", "D3F9D8"]); g.angleDegrees = 100
                return g
            }()
        ),
        WallpaperPreset(
            name: "Golden Hour Field",
            category: .nature,
            gradient: {
                var g = WallpaperGradient(); g.kind = .linear
                g.stops = stops(["FFE000", "FF7A00"]); g.angleDegrees = 90
                return g
            }()
        ),

        // MARK: Aurora
        WallpaperPreset(
            name: "Northern Lights",
            category: .aurora,
            gradient: {
                var g = WallpaperGradient(); g.kind = .linear
                g.stops = stops(["020111", "00C9A7"]); g.angleDegrees = 100
                return g
            }(),
            effects: [
                {
                    var e = WallpaperEffect.makeDefault(kind: .aurora)
                    e.x = 0.5; e.y = 0.35; e.width = 1.0; e.height = 0.5
                    e.color = CodableColor.fromHex("00D2FC")!
                    return e
                }(),
                {
                    var e = WallpaperEffect.makeDefault(kind: .aurora)
                    e.x = 0.4; e.y = 0.25; e.width = 0.9; e.height = 0.4
                    e.color = CodableColor.fromHex("845EC2")!; e.opacity = 0.4
                    return e
                }()
            ]
        ),

        // MARK: Sunset
        WallpaperPreset(
            name: "Golden Sunset",
            category: .sunset,
            gradient: {
                var g = WallpaperGradient(); g.kind = .linear
                g.stops = stops(["FF512F", "F09819"]); g.angleDegrees = 90
                return g
            }()
        ),
        WallpaperPreset(
            name: "Coastal Dusk",
            category: .sunset,
            gradient: {
                var g = WallpaperGradient(); g.kind = .linear
                g.stops = stops(["2C3E50", "FD746C"]); g.angleDegrees = 90
                return g
            }()
        ),

        // MARK: Space
        WallpaperPreset(
            name: "Deep Space",
            category: .space,
            gradient: {
                var g = WallpaperGradient(); g.kind = .radial
                g.stops = stops(["000000", "1B1035", "000000"]); g.radius = 1.3
                return g
            }(),
            effects: [
                {
                    var e = WallpaperEffect.makeDefault(kind: .noise)
                    e.opacity = 0.12; e.intensity = 0.6
                    return e
                }()
            ]
        ),
        WallpaperPreset(
            name: "Nebula",
            category: .space,
            gradient: {
                var g = WallpaperGradient(); g.kind = .radial
                g.stops = stops(["05010D", "3A0CA3", "F72585"]); g.radius = 1.2
                return g
            }()
        ),

        // MARK: Glass
        WallpaperPreset(
            name: "Frosted",
            category: .glass,
            gradient: {
                var g = WallpaperGradient(); g.kind = .linear
                g.stops = stops(["A8C0FF", "3F2B96"]); g.angleDegrees = 120
                return g
            }(),
            effects: [
                {
                    var e = WallpaperEffect.makeDefault(kind: .glass)
                    e.x = 0.5; e.y = 0.5; e.width = 0.8; e.height = 0.4
                    return e
                }()
            ]
        ),

        // MARK: Liquid
        WallpaperPreset(
            name: "Liquid Metal",
            category: .liquid,
            gradient: {
                var g = WallpaperGradient(); g.kind = .angular
                g.stops = stops(["434343", "000000", "8E9EAB", "434343"])
                return g
            }(),
            effects: [
                {
                    var e = WallpaperEffect.makeDefault(kind: .liquid)
                    e.color = .white; e.opacity = 0.25
                    return e
                }()
            ]
        ),

        // MARK: Mesh
        WallpaperPreset(
            name: "Mesh Bloom",
            category: .mesh,
            gradient: {
                var g = WallpaperGradient(); g.kind = .mesh
                g.meshPoints = [
                    MeshPoint(x: 0.1, y: 0.1, color: CodableColor.fromHex("FF6B6B")!),
                    MeshPoint(x: 0.9, y: 0.15, color: CodableColor.fromHex("FFD93D")!),
                    MeshPoint(x: 0.15, y: 0.9, color: CodableColor.fromHex("4D96FF")!),
                    MeshPoint(x: 0.85, y: 0.85, color: CodableColor.fromHex("6BCB77")!),
                    MeshPoint(x: 0.5, y: 0.5, color: CodableColor.fromHex("FFFFFF")!)
                ]
                return g
            }()
        ),

        // MARK: Dark
        WallpaperPreset(
            name: "Charcoal",
            category: .dark,
            gradient: {
                var g = WallpaperGradient(); g.kind = .linear
                g.stops = stops(["1F1C2C", "928DAB"]); g.angleDegrees = 90
                return g
            }()
        ),

        // MARK: Light
        WallpaperPreset(
            name: "Cloud Nine",
            category: .light,
            gradient: {
                var g = WallpaperGradient(); g.kind = .linear
                g.stops = stops(["E0EAFC", "CFDEF3"]); g.angleDegrees = 90
                return g
            }()
        )
    ]

    static func presets(in category: PresetCategory) -> [WallpaperPreset] {
        all.filter { $0.category == category }
    }
}
