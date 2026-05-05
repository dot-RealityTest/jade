import AppKit
import SwiftUI

enum SettingsMetrics {
    static let horizontalPadding: CGFloat = 12
    static let verticalPadding: CGFloat = 12
    static let rowVerticalPadding: CGFloat = 6
    static let sectionHeaderTopPadding: CGFloat = 10
    static let sectionHeaderBottomPadding: CGFloat = 4
    static let sectionFooterTopPadding: CGFloat = 6
    static let sectionFooterBottomPadding: CGFloat = 10
    static let labelFontSize: CGFloat = 12
    static let footnoteFontSize: CGFloat = 11
    static let controlWidth: CGFloat = 210
    static let contentMaxWidth: CGFloat = 760
    static let narrowLayoutThreshold: CGFloat = 560
    static let rowSpacing: CGFloat = 16
    static let compactRowSpacing: CGFloat = 8
}

struct SettingsContainer<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    content
                }
                .frame(
                    maxWidth: min(
                        SettingsMetrics.contentMaxWidth,
                        max(proxy.size.width - (SettingsMetrics.horizontalPadding * 2), 0)
                    ),
                    alignment: .topLeading
                )
                .padding(.horizontal, SettingsMetrics.horizontalPadding)
                .padding(.vertical, SettingsMetrics.verticalPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
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
                .font(.system(size: SettingsMetrics.footnoteFontSize, weight: .semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
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
                Divider().padding(.horizontal, SettingsMetrics.horizontalPadding)
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
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: SettingsMetrics.rowSpacing) {
                Text(label)
                    .font(.system(size: SettingsMetrics.labelFontSize))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: SettingsMetrics.horizontalPadding)
                content
                    .frame(maxWidth: SettingsMetrics.controlWidth, alignment: .trailing)
            }

            VStack(alignment: .leading, spacing: SettingsMetrics.compactRowSpacing) {
                Text(label)
                    .font(.system(size: SettingsMetrics.labelFontSize))
                    .fixedSize(horizontal: false, vertical: true)
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, SettingsMetrics.horizontalPadding)
        .padding(.vertical, SettingsMetrics.rowVerticalPadding)
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
            .frame(maxWidth: width, alignment: .trailing)
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
