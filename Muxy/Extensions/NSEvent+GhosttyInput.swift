import AppKit
import GhosttyKit

extension NSEvent {
    func ghosttyKeyEvent(
        _ action: ghostty_input_action_e,
        translationMods: NSEvent.ModifierFlags? = nil
    ) -> ghostty_input_key_s {
        var keyEvent = ghostty_input_key_s()
        keyEvent.action = action
        keyEvent.keycode = UInt32(keyCode)
        keyEvent.text = nil
        keyEvent.composing = false
        keyEvent.mods = GhosttyInputMods.from(event: self)
        keyEvent.consumed_mods = GhosttyInputMods.from(
            flags: (translationMods ?? modifierFlags).subtracting([.control, .command])
        )
        keyEvent.unshifted_codepoint = unshiftedCodepointForGhostty
        return keyEvent
    }

    private var unshiftedCodepointForGhostty: UInt32 {
        guard type == .keyDown || type == .keyUp else { return 0 }

        let normalized = KeyCombo.normalized(
            key: charactersIgnoringModifiers ?? "",
            keyCode: keyCode
        )
        if let scalar = normalized.unicodeScalars.first, normalized.unicodeScalars.count == 1 {
            return scalar.value
        }
        if let scalar = KeyCombo.scalar(for: keyCode) {
            return scalar.value
        }
        return 0
    }

    var ghosttyCharacters: String? {
        guard let characters else { return nil }

        if characters.count == 1,
           let scalar = characters.unicodeScalars.first
        {
            if scalar.value < 0x20 {
                return self.characters(byApplyingModifiers: modifierFlags.subtracting(.control))
            }
            if scalar.value >= 0xF700, scalar.value <= 0xF8FF {
                return nil
            }
        }

        return characters
    }
}

enum GhosttyInputMods {
    private enum RightModifierMask {
        static let shift: UInt = 0x04
        static let control: UInt = 0x2000
        static let option: UInt = 0x40
        static let command: UInt = 0x10
    }

    static func from(event: NSEvent) -> ghostty_input_mods_e {
        from(flags: event.modifierFlags)
    }

    static func from(flags: NSEvent.ModifierFlags) -> ghostty_input_mods_e {
        var mods = GHOSTTY_MODS_NONE.rawValue
        if flags.contains(.shift) { mods |= GHOSTTY_MODS_SHIFT.rawValue }
        if flags.contains(.control) { mods |= GHOSTTY_MODS_CTRL.rawValue }
        if flags.contains(.option) { mods |= GHOSTTY_MODS_ALT.rawValue }
        if flags.contains(.command) { mods |= GHOSTTY_MODS_SUPER.rawValue }
        if flags.contains(.capsLock) { mods |= GHOSTTY_MODS_CAPS.rawValue }
        let raw = flags.rawValue
        if raw & RightModifierMask.shift != 0 { mods |= GHOSTTY_MODS_SHIFT_RIGHT.rawValue }
        if raw & RightModifierMask.control != 0 { mods |= GHOSTTY_MODS_CTRL_RIGHT.rawValue }
        if raw & RightModifierMask.option != 0 { mods |= GHOSTTY_MODS_ALT_RIGHT.rawValue }
        if raw & RightModifierMask.command != 0 { mods |= GHOSTTY_MODS_SUPER_RIGHT.rawValue }
        return ghostty_input_mods_e(rawValue: mods)
    }
}

enum GhosttyInputText {
    static func isPrivateUseFunctionKey(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        return text.unicodeScalars.allSatisfy { scalar in
            (0xF700 ... 0xF8FF).contains(scalar.value)
        }
    }
}
