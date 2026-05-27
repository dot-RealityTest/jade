import SwiftUI

struct GhosttyConfigSettingsView: View {
    @State private var configText = ""
    @State private var hasChanges = false
    @State private var saveError: String?
    @State private var showingSaveError = false
    @State private var mode = ConfigEditMode.form
    @FocusState private var editorFocused: Bool

    @State private var fontFamily = ""
    @State private var fontSize = ""
    @State private var themeName = ""
    @State private var backgroundOpacity = ""
    @State private var cursorStyle = CursorStyle.bar
    @State private var mouseHideWhileTyping = false
    @State private var copyOnSelect = false
    @State private var windowDecoration = true
    @State private var confirmCloseSurface = true
    @State private var scrollbackLines = ""
    @State private var showThemePicker = false

    private var config: MuxyConfig { .shared }
    @State private var themeService = ThemeService.shared

    var body: some View {
        SettingsContainer {
            SettingsSection(
                "Config File",
                footer: "Path: \(config.ghosttyConfigPath)"
            ) {
                SettingsRow("Open in editor") {
                    Button("Open") {
                        NSWorkspace.shared.open(config.ghosttyConfigURL)
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            }

            SettingsSegmentedHeader(selection: $mode)

            switch mode {
            case .form:
                formContent
            case .raw:
                rawContent
            }
        }
        .task {
            loadConfig()
        }
        .alert("Save Error", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "Failed to save config file.")
        }
    }

    private var formContent: some View {
        SettingsSection("Appearance", showsDivider: false) {
            SettingsRow("Theme") {
                HStack(spacing: 6) {
                    Text(themeName.isEmpty ? "Default" : themeName)
                        .font(.system(size: SettingsMetrics.labelFontSize))
                        .foregroundStyle(themeName.isEmpty ? .secondary : .primary)
                        .lineLimit(1)

                    Button {
                        showThemePicker.toggle()
                    } label: {
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showThemePicker) {
                        ThemePicker(mode: .currentAppearance)
                            .environment(themeService)
                            .onDisappear {
                                refreshFormFromConfig()
                            }
                    }
                }
                .settingsControlFrame(alignment: .trailing)
            }

            SettingsRow("Font Family") {
                TextField("JetBrains Mono", text: $fontFamily)
                    .font(.system(size: SettingsMetrics.labelFontSize))
                    .settingsControlFrame(alignment: .trailing)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveForm() }
            }

            SettingsRow("Font Size") {
                TextField("12", text: $fontSize)
                    .font(.system(size: SettingsMetrics.labelFontSize))
                    .frame(width: 80, alignment: .trailing)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveForm() }
            }

            SettingsRow("Background Opacity") {
                TextField("1.0", text: $backgroundOpacity)
                    .font(.system(size: SettingsMetrics.labelFontSize))
                    .frame(width: 80, alignment: .trailing)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveForm() }
            }

            SettingsRow("Cursor Style") {
                Picker("", selection: $cursorStyle) {
                    ForEach(CursorStyle.allCases) { style in
                        Text(style.rawValue.capitalized).tag(style)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .settingsControlFrame()
                .onChange(of: cursorStyle) { _, _ in saveForm() }
            }

            SettingsToggleRow(
                label: "Hide mouse while typing",
                isOn: Binding(
                    get: { mouseHideWhileTyping },
                    set: { mouseHideWhileTyping = $0
                        saveForm()
                    }
                )
            )

            SettingsToggleRow(
                label: "Copy on select",
                isOn: Binding(
                    get: { copyOnSelect },
                    set: { copyOnSelect = $0
                        saveForm()
                    }
                )
            )

            SettingsToggleRow(
                label: "Window decorations",
                isOn: Binding(
                    get: { windowDecoration },
                    set: { windowDecoration = $0
                        saveForm()
                    }
                )
            )

            SettingsToggleRow(
                label: "Confirm before closing terminal",
                isOn: Binding(
                    get: { confirmCloseSurface },
                    set: { confirmCloseSurface = $0
                        saveForm()
                    }
                )
            )

            SettingsRow("Scrollback lines") {
                TextField("250000", text: $scrollbackLines)
                    .font(.system(size: SettingsMetrics.labelFontSize))
                    .frame(width: 100, alignment: .trailing)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveForm() }
            }
        }
    }

    private var rawContent: some View {
        SettingsSection("Raw Config", showsDivider: false) {
            VStack(spacing: 0) {
                TextEditor(text: $configText)
                    .font(.system(size: 12, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(Color(nsColor: .textBackgroundColor))
                    .frame(minHeight: 280)
                    .focused($editorFocused)
                    .onChange(of: configText) { _, _ in
                        hasChanges = true
                    }

                Divider()

                HStack {
                    if hasChanges {
                        Text("Unsaved changes")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Reset") {
                        loadConfig()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .disabled(!hasChanges)

                    Button("Save") {
                        saveRawConfig()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(!hasChanges)
                }
                .padding(.horizontal, SettingsMetrics.horizontalPadding)
                .padding(.vertical, 10)
            }
        }
    }

    private func loadConfig() {
        configText = config.readGhosttyConfig()
        hasChanges = false
        refreshFormFromConfig()
    }

    private func refreshFormFromConfig() {
        fontFamily = config.configValue(for: "font-family") ?? ""
        fontSize = config.configValue(for: "font-size") ?? ""
        themeName = config.configValue(for: "theme")?.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) ?? ""
        backgroundOpacity = config.configValue(for: "background-opacity") ?? ""
        cursorStyle = CursorStyle(rawValue: config.configValue(for: "cursor-style") ?? "bar") ?? .bar
        mouseHideWhileTyping = parseBool(config.configValue(for: "mouse-hide-while-typing"))
        copyOnSelect = parseBool(config.configValue(for: "copy-on-select"))
        windowDecoration = parseBool(config.configValue(for: "window-decoration"), default: true)
        confirmCloseSurface = parseBool(config.configValue(for: "confirm-close-surface"), default: true)
        scrollbackLines = config.configValue(for: "scrollback-lines") ?? ""
    }

    private func saveForm() {
        updateConfigValue("font-family", value: fontFamily.isEmpty ? nil : fontFamily)
        updateConfigValue("font-size", value: fontSize.isEmpty ? nil : fontSize)
        updateConfigValue("theme", value: themeName.isEmpty ? nil : "\"\(sanitizedThemeName(themeName))\"")
        updateConfigValue("background-opacity", value: backgroundOpacity.isEmpty ? nil : backgroundOpacity)
        updateConfigValue("cursor-style", value: cursorStyle.rawValue)
        updateConfigValue("mouse-hide-while-typing", value: mouseHideWhileTyping ? "true" : "false")
        updateConfigValue("copy-on-select", value: copyOnSelect ? "true" : "false")
        updateConfigValue("window-decoration", value: windowDecoration ? "true" : "false")
        updateConfigValue("confirm-close-surface", value: confirmCloseSurface ? "true" : "false")
        updateConfigValue("scrollback-lines", value: scrollbackLines.isEmpty ? nil : scrollbackLines)
        GhosttyService.shared.reloadConfig()
    }

    private func updateConfigValue(_ key: String, value: String?) {
        guard let value else {
            removeConfigKey(key)
            return
        }
        config.updateConfigValue(key, value: value)
    }

    private func removeConfigKey(_ key: String) {
        var content = config.readGhosttyConfig()
        var lines = content.components(separatedBy: "\n")
        guard let index = findLineIndex(for: key, in: lines) else { return }
        lines.remove(at: index)
        content = lines.joined(separator: "\n")
        try? config.writeGhosttyConfig(content)
    }

    private func findLineIndex(for key: String, in lines: [String]) -> Int? {
        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix(key) else { continue }
            let afterKey = trimmed.dropFirst(key.count).trimmingCharacters(in: .whitespaces)
            guard afterKey.hasPrefix("=") else { continue }
            return i
        }
        return nil
    }

    private func sanitizedThemeName(_ name: String) -> String {
        name.filter { $0 != "\"" && $0 != "\n" && $0 != "\r" }
    }

    private func parseBool(_ value: String?, default: Bool = false) -> Bool {
        guard let value else { return `default` }
        return value.trimmingCharacters(in: .whitespaces).lowercased() == "true"
    }

    private func saveRawConfig() {
        do {
            try config.writeGhosttyConfig(configText)
            hasChanges = false
            GhosttyService.shared.reloadConfig()
            refreshFormFromConfig()
        } catch {
            saveError = error.localizedDescription
            showingSaveError = true
        }
    }
}

private enum ConfigEditMode: String, CaseIterable, Identifiable {
    case form
    case raw

    var id: String { rawValue }
}

private enum CursorStyle: String, CaseIterable, Identifiable {
    case block
    case bar
    case underline

    var id: String { rawValue }
}
