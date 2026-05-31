import Combine
import Foundation
import os
import Sparkle

private let logger = Logger(subsystem: "app.muxy", category: "UpdateService")

enum UpdateChannel: String, CaseIterable, Identifiable {
    case stable
    case beta

    static let storageKey = "muxy.update.channel"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .stable: "Stable"
        case .beta: "Beta"
        }
    }

    var feedURL: String {
        switch self {
        case .stable:
            "https://github.com/muxy-app/muxy/releases/latest/download/appcast-\(Self.archSlug).xml"
        case .beta:
            "https://github.com/muxy-app/muxy/releases/download/beta-channel/appcast-beta-\(Self.archSlug).xml"
        }
    }

    private static var archSlug: String {
        #if arch(arm64)
        "arm64"
        #else
        "x86_64"
        #endif
    }
}

@MainActor @Observable
final class UpdateService: NSObject {
    static let shared = UpdateService()

    @ObservationIgnored private let controller: SPUStandardUpdaterController
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private let feedDelegate: FeedDelegate
    @ObservationIgnored private var hasStarted = false

    private(set) var canCheckForUpdates = false
    private(set) var availableUpdateVersion: String?

    var isEnabled: Bool {
        Self.isUpdateChecksEnabled()
    }

    var channel: UpdateChannel {
        get { feedDelegate.channel }
        set {
            guard newValue != feedDelegate.channel else { return }
            feedDelegate.channel = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: UpdateChannel.storageKey)
            availableUpdateVersion = nil
            guard isEnabled, hasStarted else { return }
            updater.checkForUpdatesInBackground()
        }
    }

    private var updater: SPUUpdater {
        controller.updater
    }

    override private init() {
        let stored = UserDefaults.standard.string(forKey: UpdateChannel.storageKey)
            .flatMap { UpdateChannel(rawValue: $0) } ?? .stable
        let delegate = FeedDelegate(channel: stored)
        feedDelegate = delegate
        controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: delegate,
            userDriverDelegate: nil
        )
        super.init()
        controller.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: \.canCheckForUpdates, on: self)
            .store(in: &cancellables)
        observeUpdateNotifications()
        applyFeatureFlags()
    }

    nonisolated static func isUpdateChecksEnabled(defaults: UserDefaults = .standard) -> Bool {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["JADE_ENABLE_UPDATES"] == "1" else { return false }
        #endif
        if defaults.object(forKey: GeneralSettingsKeys.automaticUpdateChecks) == nil {
            return true
        }
        return defaults.bool(forKey: GeneralSettingsKeys.automaticUpdateChecks)
    }

    func start() {
        applyAutomaticChecksPreference()
        guard isEnabled else {
            logger.debug("Sparkle updater disabled for this build")
            return
        }
        guard !hasStarted else { return }
        do {
            try updater.start()
            hasStarted = true
        } catch {
            logger.warning("Sparkle updater failed to start: \(error.localizedDescription)")
        }
    }

    func applyAutomaticChecksPreference(defaults: UserDefaults = .standard) {
        let enabled = Self.isUpdateChecksEnabled(defaults: defaults)
        updater.automaticallyChecksForUpdates = enabled
        updater.automaticallyDownloadsUpdates = false
        if !enabled {
            availableUpdateVersion = nil
        }
    }

    func checkForUpdates() {
        guard isEnabled, hasStarted else { return }
        controller.checkForUpdates(nil)
    }

    private func applyFeatureFlags() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["FF_UPDATE_AVAILABLE"] != nil {
            availableUpdateVersion = "0.0.0-dev"
        }
        #endif
    }

    private func observeUpdateNotifications() {
        NotificationCenter.default.publisher(for: .SUUpdaterDidFindValidUpdate)
            .compactMap { $0.userInfo?[SUUpdaterAppcastItemNotificationKey] as? SUAppcastItem }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                guard self?.isEnabled == true else { return }
                self?.availableUpdateVersion = item.displayVersionString
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .SUUpdaterDidNotFindUpdate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.availableUpdateVersion = nil
            }
            .store(in: &cancellables)
    }
}

private final class FeedDelegate: NSObject, SPUUpdaterDelegate {
    var channel: UpdateChannel

    init(channel: UpdateChannel) {
        self.channel = channel
        super.init()
    }

    func feedURLString(for _: SPUUpdater) -> String? {
        channel.feedURL
    }

    func allowedChannels(for _: SPUUpdater) -> Set<String> {
        switch channel {
        case .stable: []
        case .beta: [channel.rawValue]
        }
    }
}
