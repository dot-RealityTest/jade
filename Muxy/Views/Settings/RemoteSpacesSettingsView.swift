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
                Text(space.trimmedCommand)
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
                    .frame(width: SettingsMetrics.controlWidth)
                    .controlSize(.small)
            }

            SettingsRow("SSH Command") {
                TextField("ssh user@host", text: $draft.command)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: SettingsMetrics.labelFontSize, design: .monospaced))
                    .frame(width: SettingsMetrics.controlWidth)
                    .controlSize(.small)
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
                    }
                    .frame(width: SettingsMetrics.controlWidth, alignment: .trailing)
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
        let space = draft.remoteSpace(existingID: selectedSpaceID)
        if selectedSpaceID == nil {
            guard let saved = store.add(space) else { return }
            beginEdit(saved)
        } else {
            store.update(space)
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

    init() {}

    init(space: RemoteSpace) {
        name = space.name
        command = space.command
        colorID = space.colorID
    }

    var isBlank: Bool {
        name.isEmpty && command.isEmpty && colorID == nil
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func remoteSpace(existingID: UUID?) -> RemoteSpace {
        RemoteSpace(
            id: existingID ?? UUID(),
            name: name,
            command: command,
            colorID: colorID
        )
    }
}
