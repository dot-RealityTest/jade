# Voice Recording

Jade includes on-device voice dictation using Apple's **Speech** framework. Transcription stays on your Mac — nothing is sent to a cloud STT service.

## How to use

1. Press the **Voice Recording** shortcut (default **`⌘⇧I`**) or use the mic control on the project status bar.
2. Speak; Jade shows the recording panel with live feedback.
3. Stop recording; the transcript is inserted at the text field or terminal focus you had **before** opening the recorder.
4. If that target is gone, the transcript is copied to the clipboard instead.

## Settings

**Settings → Recording**

| Option | Behavior |
| --- | --- |
| **Press Return after inserting** | Automatically sends Return after paste (useful in terminals) |
| **Language** | On-device dictation language (only languages with installed models appear) |

If no languages appear, add a dictation language in **System Settings → Keyboard → Dictation**, then return to Jade.

## Shortcut conflict

Default shortcuts bind **`⌘⇧I`** to both **Voice Recording** and **Project Notifications**. Remap one in **Settings → Commands → Keyboard Shortcuts** so both are reachable.

## Related

- [Keyboard Shortcuts](../user-guide/keyboard-shortcuts.md)  
- [Rich Input & integrations](integrations.md) — compose before sending to terminal or Obsidian  
