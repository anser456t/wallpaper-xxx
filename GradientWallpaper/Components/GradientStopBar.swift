import SwiftUI

/// A horizontal ramp preview with draggable stop handles, letting users
/// reorder stops and adjust their position by dragging along the ramp.
struct GradientStopBar: View {
    let gradient: WallpaperGradient
    @Binding var selectedStopID: UUID?
    let onMove: (UUID, Double) -> Void
    let onMoveEnded: () -> Void

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let sortedStops = gradient.stops.sorted { $0.location < $1.location }
            let colors = sortedStops.map { $0.color.color }
            let locations = sortedStops.map { $0.location }
            let swiftStops = zip(colors, locations).map { Gradient.Stop(color: $0, location: CGFloat($1)) }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(stops: swiftStops.isEmpty ? [Gradient.Stop(color: .gray, location: 0)] : swiftStops, startPoint: .leading, endPoint: .trailing))
                    .frame(height: 34)
                    .padding(.top, 10)

                ForEach(gradient.stops) { stop in
                    let x = CGFloat(stop.location) * width
                    StopHandle(color: stop.color.color, isSelected: selectedStopID == stop.id)
                        .position(x: min(max(x, 8), width - 8), y: 44)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    selectedStopID = stop.id
                                    let newLocation = min(max(Double(value.location.x / width), 0), 1)
                                    onMove(stop.id, newLocation)
                                }
                                .onEnded { _ in onMoveEnded() }
                        )
                }
            }
        }
    }
}

private struct StopHandle: View {
    let color: Color
    let isSelected: Bool

    var body: some View {
        ZStack {
            Triangle()
                .fill(Color.primary)
                .frame(width: 14, height: 10)
                .offset(y: -12)
            Circle()
                .fill(color)
                .frame(width: 22, height: 22)
                .overlay(Circle().strokeBorder(isSelected ? Color.accentColor : Color.primary.opacity(0.3), lineWidth: isSelected ? 3 : 1.5))
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
