import Foundation

enum AppIdentity {
    static let displayName = "Jade"
    static let cliName = "jade"
    static let legacyCLIName = "muxy"
    static let legacyDisplayName = "Muxy"
    static let bundleIdentifier = "com.muxy.app"
    static let urlScheme = "muxy"

    static var helpWindowTitle: String { "\(displayName) Help" }
    static var pickerLabel: String { "\(displayName) Picker" }
    static var appSupportLabel: String { "\(displayName) App Support" }
    static var mobileAppLabel: String { "\(displayName) mobile app" }

    static func themeDisplayName(_ themeName: String) -> String {
        if themeName == legacyDisplayName { return displayName }
        if themeName.hasPrefix("\(legacyDisplayName) ") {
            return displayName + themeName.dropFirst(legacyDisplayName.count)
        }
        return themeName
    }

    static func sentence(_ text: String) -> String {
        text.replacingOccurrences(of: legacyDisplayName, with: displayName)
    }
}
