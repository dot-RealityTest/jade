import AppKit
import SwiftUI

struct MobileSettingsView: View {
    @Bindable private var service = MobileServerService.shared
    @Bindable private var devices = ApprovedDevicesStore.shared
    @State private var deviceToRevoke: ApprovedDevice?
    @State private var portText: String = ""
    @State private var portValidationError: String?
    @State private var showFreePortConfirmation = false

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
        SettingsContainer {
            SettingsSection(
                "Network",
                footer: "Allow other devices on your local network to connect to Muxy."
            ) {
                SettingsToggleRow(label: "Allow remote access", isOn: enabledBinding)

                if service.isEnabled {
                    SettingsRow("How to connect") {
                        connectionInstructions
                    }
                }

                SettingsRow("Port") {
                    TextField("\(MobileServerService.defaultPort)", text: $portText)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: SettingsMetrics.labelFontSize, design: .monospaced))
                        .frame(width: SettingsMetrics.controlWidth)
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
        .onAppear { portText = String(service.port) }
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

    private func commitPort() -> Bool {
        let trimmed = portText.trimmingCharacters(in: .whitespaces)
        guard let value = UInt16(trimmed), MobileServerService.isValid(port: value) else {
            portValidationError = "Enter a port between \(MobileServerService.minPort) and \(MobileServerService.maxPort)."
            return false
        }
        portValidationError = nil
        service.port = value
        portText = String(value)
        return true
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

    private var connectionInstructions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Access Muxy from another device on your local network or private VPN.")
                .font(.system(size: SettingsMetrics.footnoteFontSize))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let connectionURL {
                HStack(spacing: 8) {
                    Text(connectionURL)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.primary)
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(connectionURL, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)
                    .help("Copy connection URL")
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
        .padding(.vertical, 4)
    }

    private var connectionURL: String? {
        LocalNetworkAddressProvider.connectionURL(port: service.port)
    }
}
