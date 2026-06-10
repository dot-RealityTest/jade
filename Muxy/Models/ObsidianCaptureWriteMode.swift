import Foundation

enum ObsidianCaptureWriteMode: String, Codable, CaseIterable, Identifiable {
    case append
    case newFile

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .append: "Append to note"
        case .newFile: "New file each send"
        }
    }
}
