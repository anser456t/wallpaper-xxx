import Foundation

/// A simple bounded undo/redo stack over value-type snapshots. Used to
/// give the editor real undo/redo without needing a full command pattern —
/// each meaningful edit pushes a snapshot of the whole `WallpaperProject`.
final class HistoryManager<Value: Equatable> {
    private var undoStack: [Value] = []
    private var redoStack: [Value] = []
    private let limit: Int

    init(limit: Int = 60) {
        self.limit = limit
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    /// Call before mutating the current value, passing the value as it is
    /// *before* the change is applied.
    func recordSnapshot(_ value: Value) {
        if let last = undoStack.last, last == value { return }
        undoStack.append(value)
        if undoStack.count > limit {
            undoStack.removeFirst()
        }
        redoStack.removeAll()
    }

    func undo(current: Value) -> Value? {
        guard let previous = undoStack.popLast() else { return nil }
        redoStack.append(current)
        return previous
    }

    func redo(current: Value) -> Value? {
        guard let next = redoStack.popLast() else { return nil }
        undoStack.append(current)
        return next
    }

    func reset(with value: Value) {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
