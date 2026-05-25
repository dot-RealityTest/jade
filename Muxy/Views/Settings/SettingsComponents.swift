import AppKit
import SwiftUI

enum SettingsMetrics {
    static let horizontalPadding: CGFloat = 18
    static let verticalPadding: CGFloat = 14
    static let rowVerticalPadding: CGFloat = 7
    static let sectionHeaderTopPadding: CGFloat = 14
    static let sectionHeaderBottomPadding: CGFloat = 6
    static let sectionFooterTopPadding: CGFloat = 7
    static let sectionFooterBottomPadding: CGFloat = 12
    static let labelFontSize: CGFloat = 12
    static let footnoteFontSize: CGFloat = 11
    static let controlWidth: CGFloat = 220
    static let compactContentWidth: CGFloat = 380

    static func resolvedControlWidth(for contentWidth: CGFloat) -> CGFloat {
        if SettingsLayout.isCompact(contentWidth: contentWidth) {
            return max(160, contentWidth - horizontalPadding * 2)
        }
        return min(controlWidth, contentWidth - horizontalPadding * 2)
    }
}

struct SettingsSegmentedHeader<Selection: CaseIterable & Identifiable & RawRepresentable & Hashable>: View
    where Selection.RawValue == String, Selection.AllCases: RandomAccessCollection
{
    @Environment(\.settingsContentWidth) private var contentWidth
    @Binding var selection: Selection

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(Selection.allCases) { item in
                Text(item.rawValue).tag(item)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(
            maxWidth: min(320, contentWidth - SettingsMetrics.horizontalPadding * 2),
            alignment: .leading
        )
        .padding(.horizontal, SettingsMetrics.horizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }
}

struct SettingsContainer<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.vertical, 4)
        }
        .background(Color.clear)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let footer: String?
    let showsDivider: Bool
    @ViewBuilder var content: Content

    init(
        _ title: String,
        footer: String? = nil,
        showsDivider: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.footer = footer
        self.showsDivider = showsDivider
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, SettingsMetrics.horizontalPadding)
                .padding(.top, SettingsMetrics.sectionHeaderTopPadding)
                .padding(.bottom, SettingsMetrics.sectionHeaderBottomPadding)

            content

            if let footer {
                Text(footer)
                    .font(.system(size: SettingsMetrics.footnoteFontSize))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, SettingsMetrics.horizontalPadding)
                    .padding(.top, SettingsMetrics.sectionFooterTopPadding)
                    .padding(.bottom, SettingsMetrics.sectionFooterBottomPadding)
            }

            if showsDivider {
                Divider()
                    .padding(.leading, SettingsMetrics.horizontalPadding)
            }
        }
    }
}

struct SettingsRow<Content: View>: View {
    @Environment(\.settingsContentWidth) private var contentWidth
    let label: String
    @ViewBuilder var content: Content

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        Group {
            if SettingsLayout.isCompact(contentWidth: contentWidth) {
                VStack(alignment: .leading, spacing: 8) {
                    labelView
                    content
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                HStack(alignment: .center, spacing: 12) {
                    labelView
                    Spacer(minLength: 8)
                    content
                }
            }
        }
        .padding(.horizontal, SettingsMetrics.horizontalPadding)
        .padding(.vertical, SettingsMetrics.rowVerticalPadding)
        .frame(minHeight: 32)
    }

    private var labelView: some View {
        Text(label)
            .font(.system(size: SettingsMetrics.labelFontSize))
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct SettingsToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        SettingsRow(label) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }
}

struct SettingsPickerRow<Option: CaseIterable & Identifiable & RawRepresentable>: View
    where Option.RawValue == String, Option.AllCases: RandomAccessCollection
{
    let label: String
    @Binding var selection: String

    var body: some View {
        SettingsRow(label) {
            Picker("", selection: $selection) {
                ForEach(Option.allCases) { option in
                    Text(option.rawValue).tag(option.rawValue)
                }
            }
            .labelsHidden()
            .settingsControlFrame(alignment: .trailing)
        }
    }
}

extension View {
    func resetsSettingsFocusOnOutsideClick() -> some View {
        background(SettingsFocusResetView())
    }
}

private struct SettingsFocusResetView: NSViewRepresentable {
    func makeNSView(context: Context) -> SettingsFocusResetNSView {
        SettingsFocusResetNSView()
    }

    func updateNSView(_ nsView: SettingsFocusResetNSView, context: Context) {}
}

private final class SettingsFocusResetNSView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(nil)
        super.mouseDown(with: event)
    }
}
