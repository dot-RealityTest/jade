import AppKit
import Network
import SwiftUI

struct MobileSettingsView: View {
    private static let pairingFooter = """
    Scan this with the \(AppIdentity.mobileAppLabel) to add this Mac. \
    The QR carries no token — first-time pairing still needs your approval.
    """

    @Bindable private var service = MobileServerService.shared
    @Bindable private var devices = ApprovedDevicesStore.shared
    @State private var deviceToRevoke: ApprovedDevice?
    @State private var didCopyPairingLink = false
    @State private var pairingHosts: [MobilePairingHost] = []
    @State private var selectedNetwork: MobilePairingNetwork = .local
    @State private var pathMonitor: NWPathMonitor?

    var body: some View {
        SettingsContainer {
            if !service.isEnabled {
                SettingsSection(
                    "Mobile Pairing",
                    footer: "Turn on remote access under Network to pair phones and tablets.",
                    showsDivider: false
                ) {
                    Text("Remote access is off.")
                        .font(.system(size: SettingsMetrics.labelFontSize))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, SettingsMetrics.horizontalPadding)
                        .padding(.vertical, SettingsMetrics.rowVerticalPadding)
                }
            } else if let selectedHost, let uri = pairingURI(for: selectedHost) {
                SettingsSection(
                    "Pair Mobile Device",
                    footer: Self.pairingFooter
                ) {
                    pairingCard(host: selectedHost, uri: uri)
                }
            }

            SettingsSection(
                "Approved Devices",
                footer: "Revoking removes the device's access. It will need to request approval again to reconnect.",
                showsDivider: false
            ) {
                if devices.devices.isEmpty {
                    Text("No devices approved yet.")
                        .font(.system(size: SettingsMetrics.labelFontSize))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, SettingsMetrics.horizontalPadding)
                        .padding(.vertical, SettingsMetrics.rowVerticalPadding)
                } else {
                    ForEach(devices.devices) { device in
                        deviceRow(device)
                    }
                }
            }
        }
        .onAppear {
            refreshPairingHosts()
            startPathMonitor()
        }
        .onDisappear { stopPathMonitor() }
        .onChange(of: service.isEnabled) { _, _ in
            refreshPairingHosts()
        }
        .alert(
            "Revoke \(deviceToRevoke?.name ?? "device")?",
            isPresented: Binding(
                get: { deviceToRevoke != nil },
                set: { if !$0 { deviceToRevoke = nil } }
            ),
            presenting: deviceToRevoke
        ) { device in
            Button("Revoke", role: .destructive) {
                devices.revoke(deviceID: device.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("The device will be disconnected immediately and must request approval again to reconnect.")
        }
    }

    private var selectedHost: MobilePairingHost? {
        pairingHosts.first(where: { $0.network == selectedNetwork }) ?? pairingHosts.first
    }

    private func pairingURI(for host: MobilePairingHost) -> String? {
        MobilePairingService.pairingURIString(for: host, port: service.port)
    }

    private func refreshPairingHosts() {
        pairingHosts = MobilePairingService.availableHosts()
        if !pairingHosts.contains(where: { $0.network == selectedNetwork }) {
            selectedNetwork = pairingHosts.first?.network ?? .local
        }
    }

    private func startPathMonitor() {
        guard pathMonitor == nil else { return }
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { _ in
            Task { @MainActor in refreshPairingHosts() }
        }
        monitor.start(queue: .global(qos: .utility))
        pathMonitor = monitor
    }

    private func stopPathMonitor() {
        pathMonitor?.cancel()
        pathMonitor = nil
    }

    private func pairingCard(host: MobilePairingHost, uri: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if pairingHosts.count > 1 {
                Picker("Pairing network", selection: $selectedNetwork) {
                    ForEach(pairingHosts, id: \.network) { option in
                        Text(option.network.displayName).tag(option.network)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .fixedSize()
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel("Pairing network")
            }

            HStack(alignment: .top, spacing: 14) {
                MobilePairingQRView(uriString: uri, size: 132)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Open the \(AppIdentity.mobileAppLabel), tap Add device, and scan this code.")
                        .font(.system(size: SettingsMetrics.labelFontSize))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(host.host)
                        .font(.system(size: SettingsMetrics.labelFontSize, design: .monospaced))
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text("Port \(String(service.port))")
                        .font(.system(size: SettingsMetrics.footnoteFontSize))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            pairingLinkRow(uri: uri)
        }
        .padding(.horizontal, SettingsMetrics.horizontalPadding)
        .padding(.vertical, SettingsMetrics.rowVerticalPadding)
    }

    private func pairingLinkRow(uri: String) -> some View {
        HStack(spacing: 8) {
            Text(uri)
                .font(.system(size: SettingsMetrics.footnoteFontSize, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                copyPairingLink(uri)
            } label: {
                Label(
                    didCopyPairingLink ? "Copied" : "Copy",
                    systemImage: didCopyPairingLink ? "checkmark" : "doc.on.doc"
                )
                .labelStyle(.titleAndIcon)
                .font(.system(size: SettingsMetrics.footnoteFontSize, weight: .medium))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(MuxyTheme.accent)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
    }

    private func copyPairingLink(_ uri: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(uri, forType: .string)
        didCopyPairingLink = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { didCopyPairingLink = false }
        }
    }

    private func deviceRow(_ device: ApprovedDevice) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.system(size: SettingsMetrics.labelFontSize))
                Text(lastSeenText(device))
                    .font(.system(size: SettingsMetrics.footnoteFontSize))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Revoke", role: .destructive) {
                deviceToRevoke = device
            }
            .buttonStyle(.borderless)
            .font(.system(size: SettingsMetrics.footnoteFontSize))
            .foregroundStyle(.red)
        }
        .padding(.horizontal, SettingsMetrics.horizontalPadding)
        .padding(.vertical, SettingsMetrics.rowVerticalPadding)
    }

    private func lastSeenText(_ device: ApprovedDevice) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        if let seen = device.lastSeenAt {
            return "Last seen \(formatter.localizedString(for: seen, relativeTo: Date()))"
        }
        return "Approved \(formatter.localizedString(for: device.approvedAt, relativeTo: Date()))"
    }
}
