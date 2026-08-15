import Foundation

/// A named set of colors, used both as gradient presets and as reusable
/// swatches the user can save and reload.
struct ColorPalette: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var colors: [CodableColor]

    static let presets: [ColorPalette] = [
        ColorPalette(name: "Sunset", colors: ["FF512F", "F09819", "FF7E5F"].compactMap(CodableColor.fromHex)),
        ColorPalette(name: "Ocean", colors: ["005AA7", "FFFDE4", "2193B0", "6DD5ED"].compactMap(CodableColor.fromHex)),
        ColorPalette(name: "Aurora", colors: ["00C9A7", "845EC2", "4B4453", "00D2FC"].compactMap(CodableColor.fromHex)),
        ColorPalette(name: "Pastel", colors: ["FFD1DC", "C1FFD7", "C1E1FF", "FFF5BA"].compactMap(CodableColor.fromHex)),
        ColorPalette(name: "Neon", colors: ["FF00E5", "00FFF0", "FFF500", "FF0090"].compactMap(CodableColor.fromHex)),
        ColorPalette(name: "Cyberpunk", colors: ["0D0221", "FF2079", "00F0FF", "FBE40B"].compactMap(CodableColor.fromHex)),
        ColorPalette(name: "Midnight", colors: ["020111", "191621", "20202C", "3A3A52"].compactMap(CodableColor.fromHex)),
        ColorPalette(name: "Rose", colors: ["F4C4D5", "D6708A", "8E3B5D", "3A1220"].compactMap(CodableColor.fromHex)),
        ColorPalette(name: "Purple Dream", colors: ["654EA3", "EAAFC8", "C471ED", "F64F59"].compactMap(CodableColor.fromHex)),
        ColorPalette(name: "Ice", colors: ["E0F7FA", "80DEEA", "4DD0E1", "0097A7"].compactMap(CodableColor.fromHex)),
        ColorPalette(name: "Fire", colors: ["FFE000", "FF7A00", "FF3D00", "8E0000"].compactMap(CodableColor.fromHex)),
        ColorPalette(name: "Forest", colors: ["0B3D02", "1E5631", "76B947", "D3F9D8"].compactMap(CodableColor.fromHex)),
        ColorPalette(name: "Cotton Candy", colors: ["FFC6E5", "C6E5FF", "E5C6FF", "FFF3C6"].compactMap(CodableColor.fromHex)),
        ColorPalette(name: "AMOLED Dark", colors: ["000000", "0A0A0A", "141414", "1F1F1F"].compactMap(CodableColor.fromHex))
    ]

    static func randomFromPreset() -> ColorPalette {
        presets.randomElement() ?? presets[0]
    }
}
