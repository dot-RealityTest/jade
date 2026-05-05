import SwiftUI

struct ProjectInspectorPanel: View {
    let project: Project?
    let showsNotes: Bool
    let showsTodo: Bool
    @State private var store = ProjectInspectorStore.shared

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(MuxyTheme.border)
            ProjectInspectorContent(
                project: project,
                store: store,
                showsNotes: showsNotes,
                showsTodo: showsTodo
            )
        }
        .frame(width: 320)
        .background(MuxyTheme.bg)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(MuxyTheme.border)
                .frame(width: 1)
        }
        .onAppear {
            store.selectProject(project?.id)
        }
        .onChange(of: project?.id) { _, projectID in
            store.selectProject(projectID)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(project?.name ?? "No project")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if showsNotes, showsTodo {
                inspectorStatusChip("Notes")
                inspectorStatusChip("Todo")
            } else {
                Text(headerDetail)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(MuxyTheme.fgDim)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var title: String {
        if showsNotes, showsTodo { return "Inspector" }
        if showsNotes { return "Notes" }
        return "Todo"
    }

    private var symbolName: String {
        if showsNotes, showsTodo { return "sidebar.right" }
        if showsNotes { return "note.text" }
        return "checklist"
    }

    private var headerDetail: String {
        if showsNotes { return notesDetail }
        return todoDetail
    }

    private var notesDetail: String {
        let text = store.document.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "Empty" }
        let words = text.split(whereSeparator: \.isWhitespace).count
        return words == 1 ? "1 word" : "\(words) words"
    }

    private var todoDetail: String {
        let openCount = store.document.todos.count(where: { !$0.isDone })
        let doneCount = store.document.todos.count - openCount
        if store.document.todos.isEmpty { return "Empty" }
        if doneCount == 0 { return "\(openCount) open" }
        return "\(openCount) open, \(doneCount) done"
    }
}

private struct ProjectInspectorContent: View {
    let project: Project?
    let store: ProjectInspectorStore
    let showsNotes: Bool
    let showsTodo: Bool

    var body: some View {
        if project == nil {
            inspectorEmptyState(symbolName: "sidebar.right", title: "Select a project")
        } else {
            VStack(spacing: 0) {
                if showsNotes {
                    ProjectNotesView(store: store, showsSectionHeader: showsTodo)
                        .frame(
                            minHeight: showsTodo ? 150 : 280,
                            idealHeight: showsTodo ? 190 : 420,
                            maxHeight: showsTodo ? 250 : .infinity
                        )
                }
                if showsNotes, showsTodo {
                    Divider().overlay(MuxyTheme.border)
                }
                if showsTodo {
                    ProjectTodoListView(store: store, showsSectionHeader: showsNotes)
                }
            }
        }
    }
}

private struct ProjectNotesView: View {
    let store: ProjectInspectorStore
    let showsSectionHeader: Bool

    var body: some View {
        VStack(spacing: 6) {
            if showsSectionHeader {
                sectionHeader(
                    title: "Notes",
                    symbolName: "note.text",
                    detail: notesDetail
                )
            }
            ZStack(alignment: .topLeading) {
                if store.document.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Project notes...")
                        .font(.system(size: 12))
                        .foregroundStyle(MuxyTheme.fgDim)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
                TextEditor(text: Binding(
                    get: { store.document.notes },
                    set: { store.updateNotes($0) }
                ))
                .font(.system(size: 12))
                .scrollContentBackground(.hidden)
                .padding(8)
            }
        }
        .padding(.top, showsSectionHeader ? 10 : 8)
    }

    private var notesDetail: String {
        let text = store.document.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return "Empty" }
        let words = text.split(whereSeparator: \.isWhitespace).count
        return words == 1 ? "1 word" : "\(words) words"
    }
}

private struct ProjectTodoListView: View {
    let store: ProjectInspectorStore
    let showsSectionHeader: Bool
    @State private var newTodoTitle = ""

    var body: some View {
        VStack(spacing: 0) {
            guardContent
        }
    }

    private var guardContent: some View {
        VStack(spacing: 0) {
            if showsSectionHeader {
                sectionHeader(
                    title: "Todo",
                    symbolName: "checklist",
                    detail: todoDetail
                )
                .padding(.top, 10)
            }
            todoHeader
            Divider().overlay(MuxyTheme.border)
            if store.sortedTodos.isEmpty {
                inspectorEmptyState(symbolName: "checklist", title: emptyTitle)
            } else {
                todoList
            }
        }
    }

    private var todoHeader: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("New todo", text: $newTodoTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .onSubmit(addTodo)

                Button {
                    addTodo()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)
                .background(addButtonBackground, in: RoundedRectangle(cornerRadius: 5))
                .disabled(newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .help("Add Todo")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(MuxyTheme.surface, in: RoundedRectangle(cornerRadius: 7))
        }
        .padding(.horizontal, 10)
        .padding(.top, showsSectionHeader ? 10 : 12)
        .padding(.bottom, 10)
    }

    private var todoList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(store.sortedTodos) { item in
                    ProjectTodoRow(
                        item: item,
                        onToggle: { store.toggleTodo(item.id) },
                        onRename: { store.updateTodoTitle(item.id, title: $0) },
                        onDelete: { store.deleteTodo(item.id) }
                    )
                    if item.id != store.sortedTodos.last?.id {
                        Divider().padding(.leading, 44)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var emptyTitle: String {
        "No todos yet"
    }

    private var todoDetail: String {
        let openCount = store.document.todos.count(where: { !$0.isDone })
        let doneCount = store.document.todos.count - openCount
        if store.document.todos.isEmpty { return "Empty" }
        if doneCount == 0 { return "\(openCount) open" }
        return "\(openCount) open, \(doneCount) done"
    }

    @MainActor
    private var addButtonBackground: Color {
        newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? MuxyTheme.hover : MuxyTheme.surface
    }

    private func addTodo() {
        guard store.addTodo(title: newTodoTitle) != nil else { return }
        newTodoTitle = ""
    }
}

private struct ProjectTodoRow: View {
    let item: ProjectTodoItem
    let onToggle: () -> Void
    let onRename: (String) -> Void
    let onDelete: () -> Void
    @State private var draftTitle: String
    @FocusState private var focused: Bool

    init(
        item: ProjectTodoItem,
        onToggle: @escaping () -> Void,
        onRename: @escaping (String) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.item = item
        self.onToggle = onToggle
        self.onRename = onRename
        self.onDelete = onDelete
        _draftTitle = State(initialValue: item.title)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Button {
                onToggle()
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(item.isDone ? MuxyTheme.diffAddFg : MuxyTheme.fgMuted)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help(item.isDone ? "Mark Open" : "Mark Done")

            TextField("Todo", text: $draftTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(item.isDone ? MuxyTheme.fgMuted : MuxyTheme.fg)
                .strikethrough(item.isDone)
                .focused($focused)
                .onSubmit(commitRename)
                .onChange(of: focused) { _, isFocused in
                    if !isFocused { commitRename() }
                }

            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(MuxyTheme.fgMuted)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .help("Delete Todo")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .onChange(of: item.title) { _, title in
            draftTitle = title
        }
    }

    private func commitRename() {
        onRename(draftTitle)
    }
}

@MainActor
private func sectionHeader(title: String, symbolName: String, detail: String) -> some View {
    HStack(spacing: 6) {
        Image(systemName: symbolName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: 16)
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
        Spacer()
        Text(detail)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(MuxyTheme.fgDim)
    }
    .padding(.horizontal, 10)
}

@MainActor
private func inspectorStatusChip(_ title: String) -> some View {
    Text(title)
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(MuxyTheme.fgMuted)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(MuxyTheme.surface, in: Capsule())
}

private func inspectorEmptyState(symbolName: String, title: String) -> some View {
    VStack(spacing: 10) {
        Spacer()
        Image(systemName: symbolName)
            .font(.system(size: 28))
            .foregroundStyle(.secondary)
        Text(title)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
