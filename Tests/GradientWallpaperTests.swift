import XCTest
import CoreGraphics
@testable import GradientWallpaper

final class GradientModelTests: XCTestCase {

    func testHexRoundTrip() {
        let color = CodableColor.fromHex("FF6B6B")
        XCTAssertNotNil(color)
        XCTAssertEqual(color?.hexString, "FF6B6B")
    }

    func testHexWithAlphaRoundTrip() {
        let color = CodableColor.fromHex("FF6B6B80")
        XCTAssertNotNil(color)
        XCTAssertEqual(color?.hexString.count, 8)
    }

    func testInvalidHexReturnsNil() {
        XCTAssertNil(CodableColor.fromHex("ZZZZZZ"))
        XCTAssertNil(CodableColor.fromHex("12345"))
    }

    func testGradientColorAtInterpolatesBetweenStops() {
        var gradient = WallpaperGradient()
        gradient.stops = [
            GradientStop(color: CodableColor(red: 0, green: 0, blue: 0), location: 0),
            GradientStop(color: CodableColor(red: 1, green: 1, blue: 1), location: 1)
        ]
        let midColor = gradient.colorAt(location: 0.5)
        XCTAssertEqual(midColor.red, 0.5, accuracy: 0.001)
        XCTAssertEqual(midColor.green, 0.5, accuracy: 0.001)
        XCTAssertEqual(midColor.blue, 0.5, accuracy: 0.001)
    }

    func testAddAndRemoveStop() {
        var gradient = WallpaperGradient()
        gradient.addStop(at: 0.5)
        XCTAssertEqual(gradient.stops.count, 3)
        let middleID = gradient.stops[1].id
        gradient.removeStop(id: middleID)
        XCTAssertEqual(gradient.stops.count, 2)
    }

    func testRemoveStopRefusesBelowTwoStops() {
        var gradient = WallpaperGradient()
        gradient.stops = [GradientStop(color: .white, location: 0), GradientStop(color: .black, location: 1)]
        gradient.removeStop(id: gradient.stops[0].id)
        XCTAssertEqual(gradient.stops.count, 2, "Should refuse to drop below 2 stops")
    }
}

final class WallpaperRendererTests: XCTestCase {

    func testRenderProducesImageAtRequestedSize() throws {
        let project = WallpaperProject.blank()
        let size = CGSize(width: 200, height: 300)
        let image = try WallpaperRenderer.render(project, pixelSize: size)
        XCTAssertEqual(image.width, 200)
        XCTAssertEqual(image.height, 300)
    }

    func testRenderRejectsInvalidSize() {
        let project = WallpaperProject.blank()
        XCTAssertThrowsError(try WallpaperRenderer.render(project, pixelSize: .zero))
    }

    func testRenderAllGradientKinds() throws {
        for kind in GradientKind.allCases {
            var project = WallpaperProject.blank()
            project.gradient.kind = kind
            let image = try WallpaperRenderer.render(project, pixelSize: CGSize(width: 64, height: 64))
            XCTAssertEqual(image.width, 64, "Kind \(kind) should render at requested width")
        }
    }

    func testRenderWithEveryEffectKindDoesNotThrow() throws {
        for kind in EffectKind.allCases {
            var project = WallpaperProject.blank()
            project.effects = [WallpaperEffect.makeDefault(kind: kind)]
            XCTAssertNoThrow(try WallpaperRenderer.render(project, pixelSize: CGSize(width: 64, height: 64)))
        }
    }

    func testPresetsAllRenderSuccessfully() throws {
        for preset in WallpaperPreset.all {
            let project = WallpaperProject.from(preset: preset)
            XCTAssertNoThrow(try WallpaperRenderer.render(project, pixelSize: CGSize(width: 100, height: 140)), "Preset \(preset.name) should render")
        }
    }
}

final class PersistenceTests: XCTestCase {

    func testSaveAndLoadRoundTrip() throws {
        let service = PersistenceService.shared
        var project = WallpaperProject.blank(name: "Test Project \(UUID().uuidString)")
        project = try service.save(project)

        let all = service.loadAllProjects()
        XCTAssertTrue(all.contains { $0.id == project.id })

        service.delete(project)
        let allAfterDelete = service.loadAllProjects()
        XCTAssertFalse(allAfterDelete.contains { $0.id == project.id })
    }
}

final class HistoryManagerTests: XCTestCase {

    func testUndoRedoRoundTrip() {
        let history = HistoryManager<Int>()
        history.recordSnapshot(1)
        let undone = history.undo(current: 2)
        XCTAssertEqual(undone, 1)
        let redone = history.redo(current: 1)
        XCTAssertEqual(redone, 2)
    }
}
