import AppKit
import Network
import SwiftUI

struct NetworkSettingsView: View {
    var body: some View {
        SettingsContainer {
            RemoteAccessSettingsSection(showsDivider: false)
        }
    }
}

struct RemoteAccessSettingsSection: View {
    @Bindable private var service = MobileServerService.shared
    @State private var portText: String = ""
    @State private var portValidationError: String?
    @State private var showFreePortConfirmation = false
    @State private var didCopyConnectionURL = false
    @State private var pathMonitor: NWPathMonitor?
    @State private var networkRefreshGeneration = 0

    var showsDivider = true

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { service.isEnabled },
            set: { newValue in
                if newValue, !commitPort() { return }
                service.setEnabled(newValue)
            }
        )
    }

    var body: some View {
        SettingsSection(
            "Remote Access",
            footer: "Control how other devices can access \(AppIdentity.displayName) on your local network.",
            showsDivider: showsDivider
        ) {
            SettingsToggleRow(label: "Allow remote access", isOn: enabledBinding)

            if service.isEnabled {
                howToConnectCard
            }

            SettingsRow("Port") {
                TextField("\(MobileServerService.defaultPort)", text: $portText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: SettingsMetrics.labelFontSize, design: .monospaced))
                    .settingsControlFrame()
                    .onChange(of: portText) { _, _ in
                        guard portText != String(service.port) else { return }
                        portValidationError = nil
                        if service.isEnabled {
                            service.setEnabled(false)
                        }
                    }
                    .onSubmit { _ = commitPort() }
            }

            if let error = portValidationError ?? service.lastError {
                portErrorRow(error)
            }
        }
        .onAppear {
            portText = String(service.port)
            startPathMonitor()
        }
        .onDisappear { stopPathMonitor() }
        .onChange(of: service.port) { _, newValue in
            let text = String(newValue)
            if portText != text { portText = text }
        }
        .alert(
            "Free port \(String(service.port))?",
            isPresented: $showFreePortConfirmation
        ) {
            Button("Free Port", role: .destructive) {
                service.freePort()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will terminate any process currently listening on port \(String(service.port)).")
        }
    }

    private var howToConnectCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How to connect")
                .font(.system(size: SettingsMetrics.labelFontSize, weight: .semibold))
                .foregroundStyle(.primary)

            Text(
                "Access \(AppIdentity.displayName) from any device on your local network " +
                    "(e.g. iPad, phone, another computer)."
            )
            .font(.system(size: SettingsMetrics.footnoteFontSize))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            if let connectionURL {
                HStack(spacing: 8) {
                    Text(connectionURL)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        copyConnectionURL(connectionURL)
                    } label: {
                        Image(systemName: didCopyConnectionURL ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)
                    .help(didCopyConnectionURL ? "Copied" : "Copy connection URL")
                }
                .padding(10)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            } else {
                Text("No local network address is available right now.")
                    .font(.system(size: SettingsMetrics.footnoteFontSize))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, SettingsMetrics.horizontalPadding)
        .padding(.vertical, SettingsMetrics.rowVerticalPadding)
    }

    private func portErrorRow(_ error: String) -> some View {
        HStack(spacing: 6) {
            Text(error)
                .font(.system(size: SettingsMetrics.footnoteFontSize))
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
            if service.isPortInUse {
                Button("Free Port") {
                    showFreePortConfirmation = true
                }
                .font(.system(size: SettingsMetrics.footnoteFontSize, weight: .medium))
                .buttonStyle(.borderless)
                .foregroundStyle(MuxyTheme.accent)
            }
        }
        .padding(.horizontal, SettingsMetrics.horizontalPadding)
        .padding(.vertical, SettingsMetrics.rowVerticalPadding)
    }

    private func commitPort() -> Bool {
        let trimmed = portText.trimmingCharacters(in: .whitespaces)
        guard let value = UInt16(trimmed), MobileServerService.isValid(port: value) else {
            portValidationError =
                "Enter a port between \(MobileServerService.minPort) and \(MobileServerService.maxPort)."
            return false
        }
        portValidationError = nil
        service.port = value
        portText = String(value)
        return true
    }

    private var connectionURL: String? {
        _ = networkRefreshGeneration
        return LocalNetworkAddressProvider.connectionURL(port: service.port)
    }

    private func copyConnectionURL(_ url: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)
        didCopyConnectionURL = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { didCopyConnectionURL = false }
        }
    }

    private func startPathMonitor() {
        guard pathMonitor == nil else { return }
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { _ in
            Task { @MainActor in
                networkRefreshGeneration &+= 1
            }
        }
        monitor.start(queue: .global(qos: .utility))
        pathMonitor = monitor
    }

    private func stopPathMonitor() {
        pathMonitor?.cancel()
        pathMonitor = nil
    }
}
