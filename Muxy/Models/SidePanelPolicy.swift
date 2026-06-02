import Foundation

struct SidePanelVisibility: Equatable {
    var snippets: Bool
    var ai: Bool
}

enum SidePanelPolicy {
    enum Slot {
        case snippets
        case ai
    }

    static func toggling(_ slot: Slot, in visibility: SidePanelVisibility) -> SidePanelVisibility {
        var next = visibility
        switch slot {
        case .snippets:
            next.snippets.toggle()
            if next.snippets {
                next.ai = false
            }
        case .ai:
            next.ai.toggle()
            if next.ai {
                next.snippets = false
            }
        }
        return next
    }
}
