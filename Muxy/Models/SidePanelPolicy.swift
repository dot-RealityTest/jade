import Foundation

struct SidePanelVisibility: Equatable {
    var snippets: Bool
    var ai: Bool
    var notes: Bool
    var todo: Bool
}

enum SidePanelPolicy {
    enum Slot {
        case snippets
        case ai
        case inspectorNotes
        case inspectorTodo
    }

    static func toggling(_ slot: Slot, in visibility: SidePanelVisibility) -> SidePanelVisibility {
        var next = visibility
        switch slot {
        case .snippets:
            next.snippets.toggle()
            if next.snippets {
                next.ai = false
                next.notes = false
                next.todo = false
            }
        case .ai:
            next.ai.toggle()
            if next.ai {
                next.snippets = false
                next.notes = false
                next.todo = false
            }
        case .inspectorNotes:
            next.notes.toggle()
            if next.notes {
                next.snippets = false
                next.ai = false
            }
        case .inspectorTodo:
            next.todo.toggle()
            if next.todo {
                next.snippets = false
                next.ai = false
            }
        }
        return next
    }

    static func openingInspector(in visibility: SidePanelVisibility) -> SidePanelVisibility {
        var next = visibility
        next.snippets = false
        next.ai = false
        return next
    }
}
