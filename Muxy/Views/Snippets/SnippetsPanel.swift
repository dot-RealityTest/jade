import AppKit
import SwiftUI

private enum SnippetsPanelMode: Equatable {
    case list
    case create
    case edit(Snippet)
    case run(Snippet)
}

struct SnippetsPanel: View {
    let scope: SnippetScope
    var showsPanelChrome = true
    @State private var snippetsStore = SnippetsStore.shared
    @State private var mode: SnippetsPanelMode = .list

    var body: some View {
        if showsPanelChrome {
            content
                .frame(width: WindowLayoutMetrics.snippetsWidth)
                .background(MuxyTheme.bg)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(MuxyTheme.border)
                        .frame(width: 1)
                }
        } else {
            content
        }
    }

    private var content: some View {
        @Bindable var snippetsStore = snippetsStore
        let snippets = snippetsStore.filteredSnippets

        return Group {
            switch mode {
            case .list:
                listView(snippets, searchQuery: $snippetsStore.searchQuery)
            case .create:
                SnippetEditorView(
                    scope: scope,
                    store: snippetsStore,
                    snippet: nil,
                    onClose: { mode = .list }
                )
            case let .edit(snippet):
                SnippetEditorView(
                    scope: scope,
                    store: snippetsStore,
                    snippet: snippet,
                    onClose: { mode = .list }
                )
            case let .run(snippet):
                SnippetRunnerView(
                    scope: scope,
                    snippet: snippet,
                    onClose: { mode = .list }
                )
            }
        }
        .onAppear {
            snippetsStore.selectScope(scope)
        }
        .onChange(of: scope) { _, scope in
            mode = .list
            snippetsStore.selectScope(scope)
        }
    }

    private func listView(_ snippets: [Snippet], searchQuery: Binding<String>) -> some View {
        VStack(spacing: 0) {
            header(scope: scope, searchQuery: searchQuery)
            Divider()
            if snippets.isEmpty {
                emptyState
            } else {
                snippetList(snippets)
            }
        }
    }

    private func header(scope: SnippetScope, searchQuery: Binding<String>) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "curlybraces")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            TextField("Search \(scope.displayName.lowercased())", text: searchQuery)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11))
                .controlSize(.small)

            Button {
                mode = .create
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .help("New Snippet")
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "curlybraces")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("No \(scope.displayName.lowercased())")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Button("Create") {
                mode = .create
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func snippetList(_ snippets: [Snippet]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(snippets) { snippet in
                    SnippetRow(
                        snippet: snippet,
                        onRunVariables: { mode = .run(snippet) },
                        onEdit: { mode = .edit(snippet) },
                        onDelete: { snippetsStore.delete(snippet) }
                    )
                    if snippet.id != snippets.last?.id {
                        Divider().padding(.leading, 40)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct SnippetRow: View {
    let snippet: Snippet
    let onRunVariables: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(AppState.self) private var appState
    @Environment(ProjectStore.self) private var projectStore

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "curlybraces")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 14)

                Text(snippet.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                Spacer()

                Button {
                    run()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .help("Run")

                Button {
                    copyCommand()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .help("Copy")
            }

            if !snippet.trimmedDescription.isEmpty {
                Text(snippet.trimmedDescription)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 22)
            }

            Text(commandPreview)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 22)

            if !snippet.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(snippet.tags.prefix(4), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 9))
                            .foregroundStyle(MuxyTheme.accent.opacity(0.9))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(MuxyTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 3))
                    }
                }
                .padding(.leading, 22)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button("Run") {
                run()
            }
            Button("Copy Command") {
                copyCommand()
            }
            Divider()
            Button("Edit") {
                onEdit()
            }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }

    private var commandPreview: String {
        let command = snippet.trimmedCommand
        guard command.count > 60 else { return command }
        return "\(command.prefix(60))..."
    }

    private func run() {
        if snippet.hasVariables {
            onRunVariables()
            return
        }
        guard let projectID = appState.activeProjectID else {
            ToastState.shared.show("Select a project first")
            return
        }
        appState.dispatch(.createCommandTab(
            projectID: projectID,
            areaID: nil,
            name: runTitle(),
            command: runCommand(snippet.trimmedCommand)
        ))
    }

    private func runTitle() -> String {
        guard let space = activeRemoteSpace() else { return snippet.displayName }
        return "\(space.displayName) · \(snippet.displayName)"
    }

    private func runCommand(_ command: String) -> String {
        guard let space = activeRemoteSpace()
        else { return command }
        return RemoteCommandBuilder.command(command, for: space)
    }

    private func activeRemoteSpace() -> RemoteSpace? {
        guard let projectID = appState.activeProjectID,
              let project = projectStore.projects.first(where: { $0.id == projectID })
        else { return nil }
        return RemoteSpacesStore.shared.space(forProjectPath: project.path)
    }

    private func copyCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(snippet.trimmedCommand, forType: .string)
        ToastState.shared.show("Copied")
    }
}

private struct SnippetEditorView: View {
    let scope: SnippetScope
    let store: SnippetsStore
    let snippet: Snippet?
    let onClose: () -> Void
    @State private var name: String
    @State private var description: String
    @State private var command: String
    @State private var tagsText: String
    @State private var variableDefaults: [String: String]
    @FocusState private var commandFocused: Bool

    init(scope: SnippetScope, store: SnippetsStore, snippet: Snippet? = nil, onClose: @escaping () -> Void) {
        self.scope = scope
        self.store = store
        self.snippet = snippet
        self.onClose = onClose
        _name = State(initialValue: snippet?.name ?? "")
        _description = State(initialValue: snippet?.description ?? "")
        _command = State(initialValue: snippet?.command ?? "")
        _tagsText = State(initialValue: snippet?.tags.joined(separator: ", ") ?? "")
        _variableDefaults = State(initialValue: snippet?.variableDefaults ?? [:])
    }

    var body: some View {
        VStack(spacing: 0) {
            editorHeader
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                        .controlSize(.small)

                    TextField("Description", text: $description)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                        .controlSize(.small)

                    TextField("Tags", text: $tagsText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12))
                        .controlSize(.small)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Command")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)

                        TextEditor(text: $command)
                            .font(.system(size: 11, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .background(MuxyTheme.surface, in: RoundedRectangle(cornerRadius: 6))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(MuxyTheme.border, lineWidth: 1)
                            }
                            .frame(minHeight: 170)
                            .focused($commandFocused)
                    }

                    let variables = Snippet.variables(in: command)
                    if !variables.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Variables")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)

                            ForEach(variables, id: \.self) { variable in
                                HStack(spacing: 8) {
                                    Text(variable)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 72, alignment: .leading)
                                    TextField("Default", text: variableDefaultBinding(for: variable))
                                        .textFieldStyle(.roundedBorder)
                                        .font(.system(size: 11))
                                        .controlSize(.small)
                                }
                            }
                        }
                    }

                    if let snippet {
                        Button("Delete", role: .destructive) {
                            store.delete(snippet)
                            onClose()
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                    }
                }
                .padding(12)
            }
        }
        .onAppear {
            if snippet == nil {
                commandFocused = true
            }
        }
    }

    private var editorHeader: some View {
        HStack(spacing: 8) {
            Button {
                onClose()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .help("Back")

            VStack(alignment: .leading, spacing: 1) {
                Text(snippet == nil ? "New Snippet" : "Edit Snippet")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(scope.displayName)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button("Save") {
                save()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(!canSave)
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        let value = Snippet(
            id: snippet?.id ?? UUID(),
            name: name,
            description: description,
            command: command,
            tags: Snippet.normalizedTags(from: tagsText),
            variableDefaults: Snippet.normalizedVariableDefaults(variableDefaults, command: command)
        )
        if snippet == nil {
            store.add(value)
        } else {
            store.update(value)
        }
        onClose()
    }

    private func variableDefaultBinding(for variable: String) -> Binding<String> {
        Binding(
            get: { variableDefaults[variable] ?? "" },
            set: { variableDefaults[variable] = $0 }
        )
    }
}

private struct SnippetRunnerView: View {
    let scope: SnippetScope
    let snippet: Snippet
    let onClose: () -> Void
    @Environment(AppState.self) private var appState
    @Environment(ProjectStore.self) private var projectStore
    @State private var values: [String: String]

    init(scope: SnippetScope, snippet: Snippet, onClose: @escaping () -> Void) {
        self.scope = scope
        self.snippet = snippet
        self.onClose = onClose
        _values = State(initialValue: snippet.variableDefaults)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if !snippet.trimmedDescription.isEmpty {
                        Text(snippet.trimmedDescription)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(snippet.variables, id: \.self) { variable in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(variable)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                TextField(variable, text: valueBinding(for: variable))
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 12))
                                    .controlSize(.small)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Preview")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(resolvedCommand)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(MuxyTheme.surface, in: RoundedRectangle(cornerRadius: 6))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(MuxyTheme.border, lineWidth: 1)
                            }
                    }
                }
                .padding(12)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                onClose()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderless)
            .help("Back")

            VStack(alignment: .leading, spacing: 1) {
                Text(snippet.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(scope.displayName)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button("Run") {
                run()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .disabled(!canRun)
        }
        .padding(.horizontal, 10)
        .frame(height: 44)
    }

    private var resolvedCommand: String {
        snippet.resolvedCommand(values: values)
    }

    private var canRun: Bool {
        !resolvedCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && snippet.variables.allSatisfy {
                !(values[$0] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
    }

    private func run() {
        guard let projectID = appState.activeProjectID else {
            ToastState.shared.show("Select a project first")
            return
        }
        appState.dispatch(.createCommandTab(
            projectID: projectID,
            areaID: nil,
            name: runTitle(),
            command: runCommand(resolvedCommand)
        ))
        onClose()
    }

    private func runTitle() -> String {
        guard let space = activeRemoteSpace() else { return snippet.displayName }
        return "\(space.displayName) · \(snippet.displayName)"
    }

    private func runCommand(_ command: String) -> String {
        guard let space = activeRemoteSpace()
        else { return command }
        return RemoteCommandBuilder.command(command, for: space)
    }

    private func activeRemoteSpace() -> RemoteSpace? {
        guard let projectID = appState.activeProjectID,
              let project = projectStore.projects.first(where: { $0.id == projectID })
        else { return nil }
        return RemoteSpacesStore.shared.space(forProjectPath: project.path)
    }

    private func valueBinding(for variable: String) -> Binding<String> {
        Binding(
            get: { values[variable] ?? "" },
            set: { values[variable] = $0 }
        )
    }
}
