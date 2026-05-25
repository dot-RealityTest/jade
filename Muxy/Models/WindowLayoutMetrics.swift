import CoreGraphics

@MainActor
enum WindowLayoutMetrics {
    static let mainMinWidth: CGFloat = 900
    static let mainMinHeight: CGFloat = 640
    static let mainDefaultWidth: CGFloat = 1200
    static let mainDefaultHeight: CGFloat = 800

    static let settingsMinWidth: CGFloat = 520
    static let settingsIdealWidth: CGFloat = 560
    static let settingsMaxWidth: CGFloat = 640
    static let settingsMinHeight: CGFloat = 360
    static let settingsIdealHeight: CGFloat = 420
    static let settingsMaxHeight: CGFloat = 520

    static let sidebarExpandedWidth: CGFloat = 220
    static let sidebarCollapsedWidth: CGFloat = 44
    static let inspectorWidth: CGFloat = 320
    static let snippetsWidth: CGFloat = 280
    static let aiAssistantWidth: CGFloat = 340

    static let minimumMainContentWidth: CGFloat = 480

    struct AuxiliaryVisibility {
        var vcsVisible: Bool
        var vcsWidth: CGFloat
        var fileTreeVisible: Bool
        var fileTreeWidth: CGFloat
        var snippetsVisible: Bool
        var aiVisible: Bool
        var notesVisible: Bool
        var todoVisible: Bool
    }

    struct NarrowWidthAdjustments: Equatable {
        var hideAI: Bool = false
        var hideSnippets: Bool = false
        var hideInspector: Bool = false
    }

    static func sidebarWidth(
        expanded: Bool,
        collapsedStyle: SidebarCollapsedStyle,
        expandedStyle: SidebarExpandedStyle
    ) -> CGFloat {
        SidebarLayout.resolvedWidth(
            expanded: expanded,
            collapsedStyle: collapsedStyle,
            expandedStyle: expandedStyle
        ) + 1
    }

    static func auxiliaryWidth(_ visibility: AuxiliaryVisibility) -> CGFloat {
        var width: CGFloat = 0
        if visibility.vcsVisible {
            width += visibility.vcsWidth
        } else if visibility.fileTreeVisible {
            width += visibility.fileTreeWidth
        }
        if visibility.snippetsVisible {
            width += snippetsWidth
        }
        if visibility.aiVisible {
            width += aiAssistantWidth
        }
        if visibility.notesVisible || visibility.todoVisible {
            width += inspectorWidth
        }
        return width
    }

    static func mainContentWidth(windowWidth: CGFloat, sidebarWidth: CGFloat, auxiliaryWidth: CGFloat) -> CGFloat {
        windowWidth - sidebarWidth - auxiliaryWidth
    }

    static func narrowWidthAdjustments(
        windowWidth: CGFloat,
        sidebarWidth: CGFloat,
        visibility: AuxiliaryVisibility
    ) -> NarrowWidthAdjustments {
        var workingVisibility = visibility
        var adjustments = NarrowWidthAdjustments()

        func applyHideIfNeeded(_ hide: (inout NarrowWidthAdjustments) -> Void) -> Bool {
            let contentWidth = mainContentWidth(
                windowWidth: windowWidth,
                sidebarWidth: sidebarWidth,
                auxiliaryWidth: auxiliaryWidth(workingVisibility)
            )
            guard contentWidth < minimumMainContentWidth else { return false }
            hide(&adjustments)
            return true
        }

        if workingVisibility.aiVisible, applyHideIfNeeded({ $0.hideAI = true }) {
            workingVisibility.aiVisible = false
        }
        if workingVisibility.snippetsVisible, applyHideIfNeeded({ $0.hideSnippets = true }) {
            workingVisibility.snippetsVisible = false
        }
        if workingVisibility.notesVisible || workingVisibility.todoVisible,
           applyHideIfNeeded({ $0.hideInspector = true })
        {
            workingVisibility.notesVisible = false
            workingVisibility.todoVisible = false
        }

        return adjustments
    }
}
