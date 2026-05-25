import SwiftUI

private enum InspectorSection: String, CaseIterable, Identifiable {
    case notes
    case todo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .notes: "Notes"
        case .todo: "Todo"
        }
    }
}

struct ProjectInspectorPanel: View {
    let project: Project?
    let showsNotes: Bool
    let showsTodo: Bool
    @State private var store = ProjectInspectorStore.shared
    @State private var selectedSection: InspectorSection = .notes

    private var usesSegmentedInspector: Bool {
        showsNotes && showsTodo
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if usesSegmentedInspector {
                segmentedControl
                Divider().overlay(MuxyTheme.border)
            } else {
                Divider().overlay(MuxyTheme.border)
            }
            ProjectInspectorContent(
                project: project,
                store: store,
                showsNotes: resolvedShowsNotes,
                showsTodo: resolvedShowsTodo
            )
        }
        .frame(width: WindowLayoutMetrics.inspectorWidth)
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

    private var resolvedShowsNotes: Bool {
        if usesSegmentedInspector { return selectedSection == .notes }
        return showsNotes
    }

    private var resolvedShowsTodo: Bool {
        if usesSegmentedInspector { return selectedSection == .todo }
        return showsTodo
    }

    private var segmentedControl: some View {
        Picker("Inspector section", selection: $selectedSection) {
            ForEach(InspectorSection.allCases) { section in
                Text(section.title).tag(section)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .padding(.horizontal, UIMetrics.spacing6)
        .padding(.vertical, UIMetrics.spacing4)
    }

    private var header: some View {
        HStack(spacing: UIMetrics.spacing4) {
            Image(systemName: symbolName)
                .font(.system(size: UIMetrics.fontEmphasis, weight: .semibold))
                .foregroundStyle(MuxyTheme.fgMuted)
                .frame(width: UIMetrics.iconLG)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: UIMetrics.fontEmphasis, weight: .semibold))
                    .foregroundStyle(MuxyTheme.fg)
                Text(project?.name ?? "No project")
                    .font(.system(size: UIMetrics.fontCaption))
                    .foregroundStyle(MuxyTheme.fgMuted)
                    .lineLimit(1)
            }
            Spacer()
            if usesSegmentedInspector {
                Text(headerDetail)
                    .font(.system(size: UIMetrics.fontCaption, weight: .medium))
                    .foregroundStyle(MuxyTheme.fgDim)
            } else {
                Text(headerDetail)
                    .font(.system(size: UIMetrics.fontCaption, weight: .medium))
                    .foregroundStyle(MuxyTheme.fgDim)
            }
        }
        .padding(.horizontal, UIMetrics.spacing6)
        .padding(.vertical, UIMetrics.spacing4)
    }

    private var title: String {
        if usesSegmentedInspector { return "Inspector" }
        if showsNotes { return "Notes" }
        return "Todo"
    }

    private var symbolName: String {
        if usesSegmentedInspector { return "sidebar.right" }
        if showsNotes { return "note.text" }
        return "checklist"
    }

    private var headerDetail: String {
        if usesSegmentedInspector {
            switch selectedSection {
            case .notes: return notesDetail
            case .todo: return todoDetail
            }
        }
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
                            minHeight: showsTodo ? 132 : 260,
                            idealHeight: showsTodo ? 164 : 400,
                            maxHeight: showsTodo ? 220 : .infinity
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
        VStack(spacing: 0) {
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
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
                TextEditor(text: Binding(
                    get: { store.document.notes },
                    set: { store.updateNotes($0) }
                ))
                .font(.system(size: 12))
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
        .padding(.top, showsSectionHeader ? 7 : 4)
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
    @FocusState private var newTodoFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            guardContent
        }
        .onAppear {
            newTodoFocused = true
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
                .padding(.top, 7)
            }
            todoHeader
            subtleDivider
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
                    .font(.system(size: 12))
                    .focused($newTodoFocused)
                    .onSubmit(addTodo)

                Button {
                    addTodo()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(addButtonForeground)
                .frame(width: 22, height: 22)
                .background(addButtonBackground, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                .disabled(newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .help("Add Todo")
            }
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background(inputBackground, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(inputBorder, lineWidth: 1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, showsSectionHeader ? 7 : 8)
        .padding(.bottom, 8)
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
                        subtleDivider
                            .padding(.leading, 40)
                    }
                }
            }
            .padding(.vertical, 2)
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
        newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.clear : MuxyTheme.accentSoft
    }

    @MainActor
    private var addButtonForeground: Color {
        newTodoTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? MuxyTheme.fgDim : MuxyTheme.accent
    }

    @MainActor
    private var inputBackground: Color {
        newTodoFocused ? MuxyTheme.surface : MuxyTheme.hover
    }

    @MainActor
    private var inputBorder: Color {
        newTodoFocused ? MuxyTheme.accentSoft : Color.clear
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
    @State private var hovered = false
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
            .frame(width: 22, height: 22)
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
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .opacity(hovered || focused ? 1 : 0)
            .help("Delete Todo")
        }
        .padding(.horizontal, 8)
        .frame(height: 32)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .padding(.horizontal, 4)
        .onHover { hovered = $0 }
        .onChange(of: item.title) { _, title in
            draftTitle = title
        }
    }

    @MainActor
    private var rowBackground: Color {
        hovered || focused ? MuxyTheme.hover : Color.clear
    }

    private func commitRename() {
        onRename(draftTitle)
    }
}

@MainActor
private func sectionHeader(title: String, symbolName: String, detail: String) -> some View {
    HStack(spacing: 7) {
        Image(systemName: symbolName)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: 14)
        Text(title.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(MuxyTheme.fgDim)
        Spacer()
        Text(detail)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(MuxyTheme.fgDim)
    }
    .padding(.horizontal, 10)
    .padding(.bottom, 5)
}

@MainActor
private func inspectorEmptyState(symbolName: String, title: String) -> some View {
    VStack(spacing: 8) {
        Spacer()
        Image(systemName: symbolName)
            .font(.system(size: 22))
            .foregroundStyle(MuxyTheme.fgDim)
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(MuxyTheme.fgMuted)
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}

@MainActor
private var subtleDivider: some View {
    Rectangle()
        .fill(MuxyTheme.border.opacity(0.7))
        .frame(height: 1)
}
