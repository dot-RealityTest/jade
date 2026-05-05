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
}

struct SettingsSegmentedHeader<Selection: CaseIterable & Identifiable & RawRepresentable & Hashable>: View
    where Selection.RawValue == String, Selection.AllCases: RandomAccessCollection
{
    @Binding var selection: Selection

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(Selection.allCases) { item in
                Text(item.rawValue).tag(item)
            }
        }
        .labelsHidden()
        .pickerStyle(.segmented)
        .frame(maxWidth: 320, alignment: .leading)
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
    let label: String
    @ViewBuilder var content: Content

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.system(size: SettingsMetrics.labelFontSize))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Spacer()
            content
        }
        .padding(.horizontal, SettingsMetrics.horizontalPadding)
        .padding(.vertical, SettingsMetrics.rowVerticalPadding)
        .frame(minHeight: 32)
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
    var width: CGFloat = SettingsMetrics.controlWidth

    var body: some View {
        SettingsRow(label) {
            Picker("", selection: $selection) {
                ForEach(Option.allCases) { option in
                    Text(option.rawValue).tag(option.rawValue)
                }
            }
            .labelsHidden()
            .frame(width: width, alignment: .trailing)
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
