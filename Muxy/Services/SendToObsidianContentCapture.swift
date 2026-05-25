import AppKit
import Foundation

@MainActor
enum SendToObsidianContentCapture {
    static func capture(
        terminalPaneID: UUID?,
        richInputText: String?,
        richInputVisible: Bool
    ) -> String? {
        if let textView = NSApp.keyWindow?.firstResponder as? NSTextView {
            let range = textView.selectedRange()
            if range.length > 0,
               let selected = textView.textStorage?.attributedSubstring(from: range).string,
               !selected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                return selected
            }
        }

        if let paneID = terminalPaneID,
           let terminal = TerminalViewRegistry.shared.view(for: paneID),
           let selection = terminal.selectedText(),
           !selection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return selection
        }

        if richInputVisible,
           let richInputText,
           !richInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return richInputText
        }

        if let clipboard = NSPasteboard.general.string(forType: .string),
           !clipboard.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            return clipboard
        }

        return nil
    }
}
