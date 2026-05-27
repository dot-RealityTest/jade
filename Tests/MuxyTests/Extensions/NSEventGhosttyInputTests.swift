import AppKit
import GhosttyKit
import Testing

@testable import Muxy

@Suite("NSEvent Ghostty input")
struct NSEventGhosttyInputTests {
    @Test("ghosttyCharacters drops private-use arrow function key text")
    func ghosttyCharactersDropsFunctionKeyText() throws {
        let arrow = String(UnicodeScalar(NSUpArrowFunctionKey)!)
        let event = try keyEvent(characters: arrow, keyCode: 126)

        #expect(event.ghosttyCharacters == nil)
    }

    @Test("ghosttyCharacters keeps printable text")
    func ghosttyCharactersKeepsPrintableText() throws {
        let event = try keyEvent(characters: "a", keyCode: 0)

        #expect(event.ghosttyCharacters == "a")
    }

    @Test("ghosttyKeyEvent preserves macOS keyCode for arrow keys")
    func ghosttyKeyEventPreservesKeyCode() throws {
        let arrow = String(UnicodeScalar(NSUpArrowFunctionKey)!)
        let event = try keyEvent(characters: arrow, keyCode: 126)
        let keyEvent = event.ghosttyKeyEvent(GHOSTTY_ACTION_PRESS)

        #expect(keyEvent.keycode == 126)
        #expect(keyEvent.text == nil)
        #expect(keyEvent.unshifted_codepoint == 0)
    }

    @Test("ghosttyKeyEvent keeps unshifted codepoint for printable keys")
    func ghosttyKeyEventKeepsPrintableCodepoint() throws {
        let event = try keyEvent(characters: "a", keyCode: 0)
        let keyEvent = event.ghosttyKeyEvent(GHOSTTY_ACTION_PRESS)

        #expect(keyEvent.unshifted_codepoint == UInt32(Character("a").asciiValue!))
    }

    private func keyEvent(characters: String, keyCode: UInt16) throws -> NSEvent {
        guard let event = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: false,
            keyCode: keyCode
        ) else {
            throw EventCreationError()
        }
        return event
    }

    private struct EventCreationError: Error {}
}
