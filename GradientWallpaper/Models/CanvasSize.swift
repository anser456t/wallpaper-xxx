import Foundation
import CoreGraphics

/// A named output resolution/aspect ratio for the wallpaper.
struct CanvasSize: Codable, Hashable, Identifiable {
    var id: String { name }
    var name: String
    var width: Int
    var height: Int

    var pixelSize: CGSize { CGSize(width: width, height: height) }
    var aspectRatio: CGFloat { CGFloat(width) / CGFloat(height) }

    static let ipadPortrait = CanvasSize(name: "iPad Portrait", width: 2048, height: 2732)
    static let ipadLandscape = CanvasSize(name: "iPad Landscape", width: 2732, height: 2048)
    static let ipadProPortrait = CanvasSize(name: "iPad Pro 12.9\" Portrait", width: 2048, height: 2732)
    static let ipadMiniPortrait = CanvasSize(name: "iPad Mini Portrait", width: 1488, height: 2266)
    static let square = CanvasSize(name: "Square", width: 2048, height: 2048)
    static let uhd4K = CanvasSize(name: "4K", width: 3840, height: 2160)
    static let ratio16x9 = CanvasSize(name: "16:9", width: 2560, height: 1440)
    static let ratio4x3 = CanvasSize(name: "4:3", width: 2048, height: 1536)
    static let ratio3x2 = CanvasSize(name: "3:2", width: 2160, height: 1440)
    static let ratio9x16 = CanvasSize(name: "9:16 Portrait", width: 1440, height: 2560)

    static let presets: [CanvasSize] = [
        .ipadPortrait, .ipadLandscape, .ipadProPortrait, .ipadMiniPortrait,
        .square, .uhd4K, .ratio16x9, .ratio4x3, .ratio3x2, .ratio9x16
    ]

    static func custom(width: Int, height: Int) -> CanvasSize {
        CanvasSize(name: "Custom \(width)×\(height)", width: width, height: height)
    }
}

enum ExportFormat: String, Codable, CaseIterable, Identifiable {
    case png, jpeg
    var id: String { rawValue }
    var fileExtension: String { rawValue == "jpeg" ? "jpg" : "png" }
    var displayName: String { rawValue == "jpeg" ? "JPEG" : "PNG" }
}
