import SwiftUI

struct PreviewCanvasView: View {
    @EnvironmentObject var vm: WallpaperEditorViewModel
    @State private var dragStartLocation: CGPoint?

    var body: some View {
        ZStack {
            checkerboard

            GeometryReader { geo in
                let aspect = vm.project.canvasSize.aspectRatio
                let fitted = fittedSize(in: geo.size, aspect: aspect)

                ZStack {
                    if let image = vm.previewImage {
                        Image(decorative: image, scale: 1)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: fitted.width, height: fitted.height)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.thinMaterial)
                            .frame(width: fitted.width, height: fitted.height)
                            .overlay(ProgressView())
                    }

                    if vm.isRendering {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.accentColor.opacity(0.5), lineWidth: 2)
                            .frame(width: fitted.width, height: fitted.height)
                    }
                }
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .gesture(dragGesture(fittedSize: fitted))
            }
            .padding(24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func fittedSize(in container: CGSize, aspect: CGFloat) -> CGSize {
        let containerAspect = container.width / max(container.height, 1)
        if aspect > containerAspect {
            return CGSize(width: container.width, height: container.width / aspect)
        } else {
            return CGSize(width: container.height * aspect, height: container.height)
        }
    }

    /// Lets the user drag directly on the canvas to move the selected
    /// effect (or the gradient's center, if no effect is selected and the
    /// gradient kind supports a center point).
    private func dragGesture(fittedSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                let unitX = min(max(value.location.x / fittedSize.width, 0), 1)
                let unitY = min(max(value.location.y / fittedSize.height, 0), 1)

                if let id = vm.selectedEffectID, let index = vm.project.effects.firstIndex(where: { $0.id == id }) {
                    vm.applyContinuousEdit { proj in
                        proj.effects[index].x = unitX
                        proj.effects[index].y = unitY
                    }
                } else if [.radial, .angular, .diamond, .reflected].contains(vm.project.gradient.kind) {
                    vm.applyContinuousEdit { proj in
                        proj.gradient.centerX = unitX
                        proj.gradient.centerY = unitY
                    }
                }
            }
            .onEnded { _ in
                vm.commitContinuousEdit()
            }
    }

    private var checkerboard: some View {
        Canvas { context, size in
            let tile: CGFloat = 16
            var y: CGFloat = 0
            var row = 0
            while y < size.height {
                var x: CGFloat = 0
                var col = 0
                while x < size.width {
                    let isDark = (row + col) % 2 == 0
                    context.fill(
                        Path(CGRect(x: x, y: y, width: tile, height: tile)),
                        with: .color(isDark ? Color.gray.opacity(0.08) : Color.clear)
                    )
                    x += tile
                    col += 1
                }
                y += tile
                row += 1
            }
        }
        .ignoresSafeArea()
    }
}
