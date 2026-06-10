import Foundation
import Testing

@testable import Muxy

@Suite("RemoteSpacesStore")
@MainActor
struct RemoteSpacesStoreTests {
    @Test("missing persistence starts empty")
    func missingPersistenceStartsEmpty() {
        let store = RemoteSpacesStore(persistence: InMemoryRemoteSpacesPersistence())

        #expect(store.spaces.isEmpty)
        #expect(store.filteredSpaces(matching: "").isEmpty)
    }

    @Test("replaceAll trims drops empty commands and persists")
    func replaceAllTrimsDropsEmptyCommandsAndPersists() {
        let persistence = InMemoryRemoteSpacesPersistence()
        let store = RemoteSpacesStore(persistence: persistence)
        let zenID = UUID()

        store.replaceAll([
            RemoteSpace(id: zenID, name: " Zen ", command: " ssh dev@203.0.113.20 ", colorID: "blue"),
            RemoteSpace(name: "Empty", command: " "),
        ])

        let expected = [RemoteSpace(
            id: zenID,
            name: "Zen",
            command: "ssh dev@203.0.113.20",
            colorID: "blue",
            user: "dev",
            host: "203.0.113.20",
            themeName: "Muxy Zen",
            storageKey: "zen"
        )]
        #expect(store.spaces == expected)
        #expect(persistence.savedSpaces == expected)
    }

    @Test("filter matches name and command")
    func filterMatchesNameAndCommand() {
        let store = RemoteSpacesStore(persistence: InMemoryRemoteSpacesPersistence(spaces: [
            RemoteSpace(name: "Zen", command: "ssh dev@203.0.113.20", colorID: "blue"),
            RemoteSpace(name: "Alienware", command: "ssh dev@203.0.113.10", colorID: "green"),
        ]))

        #expect(store.filteredSpaces(matching: "zen").map(\.displayName) == ["Zen"])
        #expect(store.filteredSpaces(matching: "203.0.113.10").map(\.displayName) == ["Alienware"])
    }

    @Test("add update and delete persist spaces")
    func addUpdateAndDeletePersistSpaces() throws {
        let persistence = InMemoryRemoteSpacesPersistence()
        let store = RemoteSpacesStore(persistence: persistence)
        let saved = try #require(store.add(RemoteSpace(name: "Zen", command: "ssh host", colorID: "blue")))

        #expect(persistence.savedSpaces == [saved])

        let updated = try #require(store.update(RemoteSpace(
            id: saved.id,
            name: "Zen Linux",
            command: " ssh dev@host ",
            colorID: "green"
        )))

        #expect(store.spaces == [
            RemoteSpace(
                id: saved.id,
                name: "Zen Linux",
                command: "ssh dev@host",
                colorID: "green",
                user: "dev",
                host: "host",
                themeName: "Muxy Zen",
                storageKey: "zen"
            )
        ])
        #expect(updated == store.spaces[0])
        #expect(persistence.savedSpaces == store.spaces)

        store.delete(saved)

        #expect(store.spaces.isEmpty)
        #expect(persistence.savedSpaces == [])
    }

    @Test("project path resolves matching remote space")
    func projectPathResolvesMatchingRemoteSpace() throws {
        let zen = RemoteSpace(name: "Zen", command: "ssh dev@203.0.113.20", colorID: "blue")
        let store = RemoteSpacesStore(persistence: InMemoryRemoteSpacesPersistence(spaces: [zen]))

        let space = try #require(store.space(forProjectPath: zen.backingDirectory(create: false).path))

        #expect(space.displayName == "Zen")
    }

    @Test("renaming a space keeps its storage location stable")
    func renameKeepsStorageStable() throws {
        let store = RemoteSpacesStore(persistence: InMemoryRemoteSpacesPersistence())
        let saved = try #require(store.add(RemoteSpace(name: "Alienware", command: "ssh host")))
        let originalDirectory = saved.backingDirectory(create: false).path

        let renamed = try #require(store.update(RemoteSpace(
            id: saved.id,
            name: "Alienware Linux",
            command: "ssh host"
        )))

        #expect(renamed.storageKey == saved.storageKey)
        #expect(renamed.backingDirectory(create: false).path == originalDirectory)
    }

    @Test("structured profile saves generated command fields")
    func structuredProfileSavesGeneratedCommandFields() throws {
        let persistence = InMemoryRemoteSpacesPersistence()
        let store = RemoteSpacesStore(persistence: persistence)
        let saved = try #require(store.add(RemoteSpace(
            name: "Zen",
            colorID: "blue",
            user: " dev ",
            host: " 203.0.113.20 ",
            port: 2222,
            identityFile: " ~/.ssh/id_ed25519 ",
            jumpHost: " bastion ",
            startupCommands: [" cd ~/code ", " ", " tmux attach "]
        )))

        #expect(saved.connectionCommand == "ssh -t -p 2222 -i ~/.ssh/id_ed25519 -J bastion dev@203.0.113.20 'cd ~/code && tmux attach; exec ${SHELL:-/bin/sh} -l'")
        #expect(persistence.savedSpaces == [saved])
    }
}

private final class InMemoryRemoteSpacesPersistence: RemoteSpacesPersisting {
    var spaces: [RemoteSpace]
    var savedSpaces: [RemoteSpace]?

    init(spaces: [RemoteSpace] = []) {
        self.spaces = spaces
    }

    func loadRemoteSpaces() throws -> [RemoteSpace] {
        spaces
    }

    func saveRemoteSpaces(_ spaces: [RemoteSpace]) throws {
        savedSpaces = spaces
    }
}
