import SwiftUI

struct AIUsageSettingsView: View {
    private let usageService = AIUsageService.shared
    @AppStorage(AIUsageSettingsStore.usageEnabledKey) private var usageEnabled = false
    @AppStorage(AIUsageSettingsStore.showSecondaryLimitsKey) private var showSecondaryLimits = AIUsageSettingsStore
        .defaultShowSecondaryLimits
    @State private var usageDisplayMode = AIUsageSettingsStore.usageDisplayMode()
    @State private var autoRefreshInterval = AIUsageSettingsStore.autoRefreshInterval()

    private var providers: [AIUsageProviderCatalogEntry] {
        AIUsageProviderCatalog.providers
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.width < SettingsMetrics.narrowLayoutThreshold

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Text("AI Usage")
                        .font(.system(size: 12, weight: .medium))

                    Spacer()

                    Toggle("", isOn: $usageEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .scaleEffect(0.9)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 6)

                Divider().padding(.horizontal, 12)

                if usageEnabled {
                    enabledSettings(isCompact: isCompact)
                } else {
                    disabledSettings
                }

                Spacer(minLength: 0)
            }
        }
        .onChange(of: usageEnabled) { _, enabled in
            AIUsageSettingsStore.setUsageEnabled(enabled)
            if enabled {
                refreshUsage()
            }
        }
        .onChange(of: usageDisplayMode) { _, newValue in
            AIUsageSettingsStore.setUsageDisplayMode(newValue)
        }
        .onChange(of: autoRefreshInterval) { _, newValue in
            AIUsageSettingsStore.setAutoRefreshInterval(newValue)
        }
        .onChange(of: showSecondaryLimits) { _, _ in
            usageService.recomposeSnapshots()
        }
    }

    private var disabledSettings: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Enable AI Usage to show the usage board in the sidebar.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
    }

    private func enabledSettings(isCompact: Bool) -> some View {
        VStack(spacing: 0) {
            settingsLine(isCompact: isCompact) {
                Text("Show")
                    .font(.system(size: 12, weight: .medium))
            } control: {
                Picker("Show", selection: $usageDisplayMode) {
                    ForEach(AIUsageDisplayMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 6)

            Divider().padding(.horizontal, 12)

            settingsLine(isCompact: isCompact) {
                Text("Auto Refresh")
                    .font(.system(size: 12, weight: .medium))
            } control: {
                Picker("Auto Refresh", selection: $autoRefreshInterval) {
                    ForEach(AIUsageAutoRefreshInterval.allCases) { interval in
                        Text(interval.label).tag(interval)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: 120, alignment: .trailing)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 6)

            Divider().padding(.horizontal, 12)

            settingsLine(isCompact: isCompact, alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show Secondary Limits")
                        .font(.system(size: 12, weight: .medium))
                    Text("Display weekly and monthly quotas alongside the primary session usage.")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } control: {
                Toggle("", isOn: $showSecondaryLimits)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .scaleEffect(0.9)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 6)

            Divider().padding(.horizontal, 12)

            settingsLine(isCompact: isCompact, alignment: .top) {
                Text("Choose which providers appear on the usage board.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } control: {
                HStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Button {
                        refreshUsage()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10, weight: .semibold))
                            Text("Refresh")
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .buttonStyle(.borderless)
                    .disabled(usageService.isRefreshing)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider().padding(.horizontal, 12)

            ScrollView {
                LazyVGrid(columns: gridColumns(isCompact: isCompact), spacing: 8) {
                    ForEach(providers) { provider in
                        providerCell(provider)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
    }

    private func providerCell(_ provider: AIUsageProviderCatalogEntry) -> some View {
        HStack(spacing: 8) {
            ProviderIconView(iconName: provider.iconName, size: 16, style: .monochrome(.primary))

            VStack(alignment: .leading, spacing: 2) {
                Text(provider.displayName)
                    .font(.system(size: 12))
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                if provider.hasNotificationIntegration {
                    Text("Integrated")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Toggle("", isOn: providerToggleBinding(for: provider))
                .labelsHidden()
                .toggleStyle(.switch)
                .scaleEffect(0.9)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private func gridColumns(isCompact: Bool) -> [GridItem] {
        if isCompact {
            return [GridItem(.flexible(minimum: 0), spacing: 12)]
        }
        return [
            GridItem(.flexible(minimum: 140), spacing: 12),
            GridItem(.flexible(minimum: 140), spacing: 12),
        ]
    }

    private func settingsLine(
        isCompact: Bool,
        alignment: VerticalAlignment = .center,
        @ViewBuilder label: () -> some View,
        @ViewBuilder control: () -> some View
    ) -> some View {
        Group {
            if isCompact {
                VStack(alignment: .leading, spacing: 8) {
                    label()
                    control()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(alignment: alignment, spacing: 8) {
                    label()
                    Spacer(minLength: 12)
                    control()
                }
            }
        }
    }

    private func providerToggleBinding(for provider: AIUsageProviderCatalogEntry) -> Binding<Bool> {
        Binding(
            get: {
                AIUsageProviderTrackingStore.isTracked(providerID: provider.id)
            },
            set: { isOn in
                AIUsageProviderTrackingStore.setTracked(isOn, providerID: provider.id)
                usageService.recomposeSnapshots()
            }
        )
    }

    private func refreshUsage() {
        Task {
            await usageService.refresh(force: true)
        }
    }
}
