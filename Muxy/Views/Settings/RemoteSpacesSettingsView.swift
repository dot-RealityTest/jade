import MuxyShared
import SwiftUI

struct RemoteSpacesSettingsView: View {
    @State private var store = RemoteSpacesStore.shared
    @State private var selectedSpaceID: UUID?
    @State private var draft = RemoteSpaceDraft()
    @State private var showColorPicker = false

    private var selectedSpace: RemoteSpace? {
        guard let selectedSpaceID else { return nil }
        return store.spaces.first { $0.id == selectedSpaceID }
    }

    var body: some View {
        @Bindable var store = store

        SettingsContainer {
            SettingsSection("Spaces") {
                if store.spaces.isEmpty {
                    emptyState
                } else {
                    ForEach(store.spaces) { space in
                        remoteSpaceRow(space)
                    }
                }

                SettingsRow("") {
                    Button {
                        beginCreate()
                    } label: {
                        Label("Add Space", systemImage: "plus")
                    }
                    .controlSize(.small)
                }
            }

            SettingsSection(editorTitle, showsDivider: false) {
                editorRows
            }
        }
        .onAppear {
            if draft.isBlank, let first = store.spaces.first {
                beginEdit(first)
            }
        }
        .onChange(of: selectedSpaceID) { _, id in
            guard let id, let space = store.spaces.first(where: { $0.id == id }) else { return }
            draft = RemoteSpaceDraft(space: space)
        }
    }

    private var emptyState: some View {
        Text("No remote spaces.")
            .font(.system(size: SettingsMetrics.labelFontSize))
            .foregroundStyle(.secondary)
            .padding(.horizontal, SettingsMetrics.horizontalPadding)
            .padding(.vertical, SettingsMetrics.rowVerticalPadding)
    }

    private func remoteSpaceRow(_ space: RemoteSpace) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(ProjectIconColor.color(for: space.colorID) ?? MuxyTheme.accent)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(space.displayName)
                    .font(.system(size: SettingsMetrics.labelFontSize))
                Text(space.connectionSummary)
                    .font(.system(size: SettingsMetrics.footnoteFontSize, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button("Edit") {
                beginEdit(space)
            }
            .buttonStyle(.borderless)
            .font(.system(size: SettingsMetrics.footnoteFontSize))
        }
        .padding(.horizontal, SettingsMetrics.horizontalPadding)
        .padding(.vertical, SettingsMetrics.rowVerticalPadding)
        .background(
            selectedSpaceID == space.id ? MuxyTheme.accentSoft : .clear,
            in: RoundedRectangle(cornerRadius: 6)
        )
        .padding(.horizontal, SettingsMetrics.horizontalPadding / 2)
        .contentShape(Rectangle())
        .onTapGesture {
            beginEdit(space)
        }
    }

    private var editorTitle: String {
        selectedSpace == nil ? "New Space" : "Edit Space"
    }

    private var colorName: String {
        ProjectIconColor.swatch(for: draft.colorID)?.name ?? "Default"
    }

    private var editorRows: some View {
        VStack(spacing: 0) {
            SettingsRow("Name") {
                TextField("Zen", text: $draft.name)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: SettingsMetrics.controlWidth)
                    .controlSize(.small)
            }

            SettingsRow("SSH Command") {
                TextField("ssh user@host", text: $draft.command)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: SettingsMetrics.labelFontSize, design: .monospaced))
                    .frame(maxWidth: SettingsMetrics.controlWidth)
                    .controlSize(.small)
            }

            SettingsRow("Host") {
                TextField("100.86.62.100", text: $draft.host)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: SettingsMetrics.labelFontSize, design: .monospaced))
                    .frame(maxWidth: SettingsMetrics.controlWidth)
                    .controlSize(.small)
            }

            SettingsRow("User") {
                TextField(NSUserName(), text: $draft.user)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: SettingsMetrics.labelFontSize, design: .monospaced))
                    .frame(maxWidth: SettingsMetrics.controlWidth)
                    .controlSize(.small)
            }

            SettingsRow("Port") {
                TextField("22", text: $draft.portText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: SettingsMetrics.labelFontSize, design: .monospaced))
                    .frame(maxWidth: SettingsMetrics.controlWidth)
                    .controlSize(.small)
            }

            SettingsRow("Identity") {
                TextField("~/.ssh/id_ed25519", text: $draft.identityFile)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: SettingsMetrics.labelFontSize, design: .monospaced))
                    .frame(maxWidth: SettingsMetrics.controlWidth)
                    .controlSize(.small)
            }

            SettingsRow("Jump Host") {
                TextField("bastion", text: $draft.jumpHost)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: SettingsMetrics.labelFontSize, design: .monospaced))
                    .frame(maxWidth: SettingsMetrics.controlWidth)
                    .controlSize(.small)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Startup")
                        .font(.system(size: SettingsMetrics.labelFontSize))
                    Spacer()
                    Text("one command per line")
                        .font(.system(size: SettingsMetrics.footnoteFontSize))
                        .foregroundStyle(.secondary)
                }
                TextEditor(text: $draft.startupCommandsText)
                    .font(.system(size: SettingsMetrics.labelFontSize, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .frame(height: 70)
                    .padding(4)
                    .background(MuxyTheme.surface, in: RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(MuxyTheme.border)
                    )
            }
            .padding(.horizontal, SettingsMetrics.horizontalPadding)
            .padding(.vertical, SettingsMetrics.rowVerticalPadding)

            SettingsRow("Preview") {
                Text(draft.commandPreview)
                    .font(.system(size: SettingsMetrics.footnoteFontSize, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .frame(maxWidth: SettingsMetrics.controlWidth, alignment: .trailing)
                    .textSelection(.enabled)
            }

            SettingsRow("Theme") {
                Picker("", selection: $draft.themeName) {
                    Text("Automatic").tag("")
                    Text("Muxy Zen").tag("Muxy Zen")
                    Text("Muxy Alienware").tag("Muxy Alienware")
                    Text("Muxy").tag("Muxy")
                    Text("Muxy Light").tag("Muxy Light")
                }
                .labelsHidden()
                .frame(maxWidth: SettingsMetrics.controlWidth, alignment: .trailing)
            }

            SettingsRow("Color") {
                Button {
                    showColorPicker = true
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(ProjectIconColor.color(for: draft.colorID) ?? MuxyTheme.accent)
                            .frame(width: 12, height: 12)
                        Text(colorName)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: SettingsMetrics.controlWidth, alignment: .trailing)
                }
                .controlSize(.small)
                .popover(isPresented: $showColorPicker, arrowEdge: .trailing) {
                    ProjectIconColorPicker(selectedID: draft.colorID) { colorID in
                        draft.colorID = colorID
                        showColorPicker = false
                    }
                }
            }

            HStack {
                if let selectedSpace {
                    Button("Delete", role: .destructive) {
                        delete(selectedSpace)
                    }
                    .controlSize(.small)
                }

                Spacer()

                Button("Clear") {
                    beginCreate()
                }
                .controlSize(.small)

                Button("Save") {
                    save()
                }
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
                .disabled(!draft.canSave)
            }
            .padding(.horizontal, SettingsMetrics.horizontalPadding)
            .padding(.vertical, SettingsMetrics.rowVerticalPadding)
        }
    }

    private func beginCreate() {
        showColorPicker = false
        selectedSpaceID = nil
        draft = RemoteSpaceDraft()
    }

    private func beginEdit(_ space: RemoteSpace) {
        showColorPicker = false
        selectedSpaceID = space.id
        draft = RemoteSpaceDraft(space: space)
    }

    private func save() {
        guard draft.canSave else {
            ToastState.shared.show("Add a name and host")
            return
        }
        let space = draft.remoteSpace(existingID: selectedSpaceID)
        if selectedSpaceID == nil {
            guard let saved = store.add(space) else {
                ToastState.shared.show("Could not save space")
                return
            }
            beginEdit(saved)
            ToastState.shared.show("Saved \(saved.displayName)")
        } else {
            guard let saved = store.update(space) else {
                ToastState.shared.show("Could not save space")
                return
            }
            beginEdit(saved)
            ToastState.shared.show("Saved \(saved.displayName)")
        }
    }

    private func delete(_ space: RemoteSpace) {
        store.delete(space)
        if let next = store.spaces.first {
            beginEdit(next)
        } else {
            beginCreate()
        }
    }
}

private struct RemoteSpaceDraft {
    var name = ""
    var command = ""
    var colorID: String?
    var user = ""
    var host = ""
    var portText = ""
    var identityFile = ""
    var jumpHost = ""
    var startupCommandsText = ""
    var themeName = ""

    init() {}

    init(space: RemoteSpace) {
        name = space.name
        command = space.trimmedHost.isEmpty ? space.command : ""
        colorID = space.colorID
        user = space.user
        host = space.host
        portText = space.port.map(String.init) ?? ""
        identityFile = space.identityFile
        jumpHost = space.jumpHost
        startupCommandsText = space.startupCommands.joined(separator: "\n")
        themeName = space.trimmedThemeName
    }

    var isBlank: Bool {
        name.isEmpty
            && command.isEmpty
            && colorID == nil
            && user.isEmpty
            && host.isEmpty
            && portText.isEmpty
            && identityFile.isEmpty
            && jumpHost.isEmpty
            && startupCommandsText.isEmpty
            && themeName.isEmpty
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && isPortValid
            && (!host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    var isPortValid: Bool {
        let text = portText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return true }
        guard let port = Int(text) else { return false }
        return (1 ... 65535).contains(port)
    }

    var port: Int? {
        let text = portText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        return Int(text)
    }

    var startupCommands: [String] {
        startupCommandsText
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var commandPreview: String {
        remoteSpace(existingID: nil).connectionCommand
    }

    func remoteSpace(existingID: UUID?) -> RemoteSpace {
        RemoteSpace(
            id: existingID ?? UUID(),
            name: name,
            command: command,
            colorID: colorID,
            user: user,
            host: host,
            port: port,
            identityFile: identityFile,
            jumpHost: jumpHost,
            startupCommands: startupCommands,
            themeName: themeName
        )
    }
}
