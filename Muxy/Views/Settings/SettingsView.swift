import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
            AppearanceSettingsView()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            EditorSettingsView()
                .tabItem { Label("Editor", systemImage: "pencil.line") }
            KeyboardShortcutsSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
            NotificationSettingsView()
                .tabItem { Label("Notifications", systemImage: "bell") }
            MobileSettingsView()
                .tabItem { Label("Mobile", systemImage: "iphone") }
            RemoteSpacesSettingsView()
                .tabItem { Label("Remote", systemImage: "network") }
            AIUsageSettingsView()
                .tabItem { Label("AI Usage", systemImage: "chart.bar") }
        }
        .frame(minWidth: 420, idealWidth: 620, minHeight: 520, idealHeight: 680)
        .resetsSettingsFocusOnOutsideClick()
    }
}
