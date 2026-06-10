import Foundation
import Testing
@testable import Muxy

@Suite("Obsidian Note Path Builder")
struct ObsidianNotePathBuilderTests {
    @Test("slugify normalizes titles")
    func slugifyNormalizesTitles() {
        #expect(ObsidianNotePathBuilder.slugify("Hello World!") == "hello-world")
        #expect(ObsidianNotePathBuilder.slugify("   ") == "capture")
    }

    @Test("inbox path uses folder and slug")
    func inboxPathUsesFolderAndSlug() {
        let path = ObsidianNotePathBuilder.inboxNotePath(
            inboxFolder: "Jade/Inbox",
            titleHint: "Fix MCP wiring"
        )
        #expect(path.hasPrefix("Jade/Inbox/"))
        #expect(path.hasSuffix("-fix-mcp-wiring.md"))
    }

    @Test("title uses first line")
    func titleUsesFirstLine() {
        let title = ObsidianNotePathBuilder.title(from: "First line\nSecond line")
        #expect(title == "First line")
    }
}

@Suite("Obsidian MCP Settings")
struct ObsidianMCPSettingsTests {
    @Test("can send via direct vault without MCP server")
    func canSendViaDirectVaultWithoutMCPServer() {
        var settings = ObsidianMCPSettings.defaults
        settings.vaultPath = "/tmp/vault"
        settings.preferDirectVaultWrite = true
        #expect(settings.canSendViaDirectVault == false)

        try? FileManager.default.createDirectory(
            atPath: settings.vaultPath,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(atPath: settings.vaultPath) }

        #expect(settings.canSendViaDirectVault)
        #expect(settings.canSendCaptures)
        #expect(settings.canSendNotes == false)
    }

    @Test("can send requires writable configured server")
    func canSendRequiresWritableConfiguredServer() {
        var settings = ObsidianMCPSettings.defaults
        #expect(settings.canSendNotes == false)

        settings.isEnabled = true
        settings.vaultPath = "/tmp/vault"
        settings.serverScriptPath = "/tmp/server.py"
        #expect(settings.canSendNotes == true)

        settings.readOnly = true
        #expect(settings.canSendNotes == false)
    }

    @Test("server environment maps vault flags")
    func serverEnvironmentMapsVaultFlags() {
        var settings = ObsidianMCPSettings.defaults
        settings.vaultPath = "/Users/me/Vault"
        settings.readOnly = true
        settings.backupOnWrite = false

        #expect(settings.serverEnvironment["OBSIDIAN_VAULT_PATH"] == "/Users/me/Vault")
        #expect(settings.serverEnvironment["OBSIDIAN_READ_ONLY"] == "true")
        #expect(settings.serverEnvironment["OBSIDIAN_BACKUP_ON_WRITE"] == "false")
    }

    @Test("mcp tool actions reflect configuration")
    func mcpToolActionsReflectConfiguration() {
        var settings = ObsidianMCPSettings.defaults
        #expect(ObsidianMCPToolAction.openSettings.isAvailable(for: settings))
        #expect(!ObsidianMCPToolAction.listInboxNotes.isAvailable(for: settings))

        settings.isEnabled = true
        settings.vaultPath = "/tmp/vault"
        settings.serverScriptPath = "/tmp/server.py"
        #expect(ObsidianMCPToolAction.listInboxNotes.isAvailable(for: settings))
    }
}

@Suite("Obsidian MCP Menu")
struct ObsidianMCPMenuTests {
    @Test("menu trigger encodes action")
    func menuTriggerEncodesAction() {
        let notification = Notification(
            name: .runObsidianMCPTool,
            object: nil,
            userInfo: [
                ObsidianMCPToolUserInfoKey.action: ObsidianMCPToolAction.listInboxNotes.rawValue,
                ObsidianMCPToolUserInfoKey.query: "hello",
            ]
        )
        #expect(ObsidianMCPMenuTrigger.decodedAction(from: notification) == .listInboxNotes)
        #expect(ObsidianMCPMenuTrigger.decodedQuery(from: notification) == "hello")
    }
}

@Suite("MCP JSON-RPC")
struct MCPJSONRPCTests {
    @Test("encode request appends newline")
    func encodeRequestAppendsNewline() throws {
        let data = try MCPJSONRPC.encodeRequest(id: 1, method: "initialize", params: [:])
        let line = String(decoding: data, as: UTF8.self)
        #expect(line.hasSuffix("\n"))
        #expect(line.contains("\"jsonrpc\":\"2.0\""))
        #expect(line.contains("\"method\":\"initialize\""))
    }

    @Test("decode response extracts error")
    func decodeResponseExtractsError() throws {
        let response = try MCPJSONRPC.decodeResponseLine(
            #"{"jsonrpc":"2.0","id":2,"error":{"code":-1,"message":"tool failed"}}"#
        )
        #expect(response.id == 2)
        #expect(response.error == "tool failed")
    }
}
