import SwiftUI

/// A Codable, hashable RGBA color representation used throughout the app's
/// models so that gradients, effects, and palettes can be persisted to disk.
struct CodableColor: Codable, Hashable, Identifiable {
    var id = UUID()
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(color: Color) {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.alpha = Double(a)
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    var cgColor: CGColor {
        CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    var uiColor: UIColor {
        UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// Six or eight character hex string (RRGGBB or RRGGBBAA).
    var hexString: String {
        let r = Int((red * 255).rounded())
        let g = Int((green * 255).rounded())
        let b = Int((blue * 255).rounded())
        if alpha >= 0.999 {
            return String(format: "%02X%02X%02X", r, g, b)
        } else {
            let a = Int((alpha * 255).rounded())
            return String(format: "%02X%02X%02X%02X", r, g, b, a)
        }
    }

    static func fromHex(_ hex: String) -> CodableColor? {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "#", with: "")
        guard s.count == 6 || s.count == 8 else { return nil }
        var value: UInt64 = 0
        guard Scanner(string: s).scanHexInt64(&value) else { return nil }

        if s.count == 6 {
            let r = Double((value & 0xFF0000) >> 16) / 255.0
            let g = Double((value & 0x00FF00) >> 8) / 255.0
            let b = Double(value & 0x0000FF) / 255.0
            return CodableColor(red: r, green: g, blue: b, alpha: 1.0)
        } else {
            let r = Double((value & 0xFF000000) >> 24) / 255.0
            let g = Double((value & 0x00FF0000) >> 16) / 255.0
            let b = Double((value & 0x0000FF00) >> 8) / 255.0
            let a = Double(value & 0x000000FF) / 255.0
            return CodableColor(red: r, green: g, blue: b, alpha: a)
        }
    }

    static let white = CodableColor(red: 1, green: 1, blue: 1)
    static let black = CodableColor(red: 0, green: 0, blue: 0)

    static func random() -> CodableColor {
        CodableColor(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1),
            alpha: 1.0
        )
    }

    /// HSB accessors used by the HSB slider panel.
    var hsb: (h: Double, s: Double, b: Double) {
        let ui = uiColor
        var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0, a: CGFloat = 0
        ui.getHue(&h, saturation: &s, brightness: &br, alpha: &a)
        return (Double(h), Double(s), Double(br))
    }

    static func fromHSB(h: Double, s: Double, b: Double, alpha: Double = 1.0) -> CodableColor {
        let ui = UIColor(hue: h, saturation: s, brightness: b, alpha: alpha)
        return CodableColor(color: Color(ui))
    }
}
