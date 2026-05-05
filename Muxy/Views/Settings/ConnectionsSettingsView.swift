import SwiftUI

struct ConnectionsSettingsView: View {
    private enum Section: String, CaseIterable, Identifiable {
        case remote = "Remote"
        case mobile = "Mobile"
        case usage = "AI Usage"

        var id: String { rawValue }
    }

    @State private var section: Section = .remote

    var body: some View {
        VStack(spacing: 0) {
            SettingsSegmentedHeader(selection: $section)

            Divider()

            switch section {
            case .remote:
                RemoteSpacesSettingsView()
            case .mobile:
                MobileSettingsView()
            case .usage:
                AIUsageSettingsView()
            }
        }
    }
}
