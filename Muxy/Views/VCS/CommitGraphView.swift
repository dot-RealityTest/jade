import SwiftUI

struct CommitGraphView: View {
    let prefix: String

    private static let columnColors: [Color] = [
        Color(hex: 0x58A6FF),
        Color(hex: 0xF0883E),
        Color(hex: 0x3FB950),
        Color(hex: 0xA371F7),
        Color(hex: 0xF85149),
        Color(hex: 0x56D4DD),
        Color(hex: 0xD2A8FF),
        Color(hex: 0x79C0FF),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(prefix.enumerated()), id: \.offset) { index, character in
                graphCell(for: character, column: index)
                    .frame(width: 9, height: 40)
            }
        }
    }

    private func graphCell(for character: Character, column: Int) -> some View {
        let color = Self.columnColors[column % Self.columnColors.count]
        return ZStack {
            switch character {
            case "*":
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
            case "o":
                Circle()
                    .stroke(color, lineWidth: 1.5)
                    .frame(width: 6, height: 6)
            case "|":
                Rectangle()
                    .fill(color)
                    .frame(width: 1.5)
            case "\\":
                DiagonalLine(direction: .downRight, color: color)
            case "/":
                DiagonalLine(direction: .downLeft, color: color)
            case "-",
                 "_":
                Rectangle()
                    .fill(color)
                    .frame(height: 1.5)
            case ".":
                Circle()
                    .fill(color)
                    .frame(width: 3, height: 3)
            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum DiagonalDirection {
    case downLeft
    case downRight
}

private struct DiagonalLine: View {
    let direction: DiagonalDirection
    let color: Color

    var body: some View {
        GeometryReader { geo in
            Path { path in
                switch direction {
                case .downLeft:
                    path.move(to: CGPoint(x: geo.size.width, y: .zero))
                    path.addLine(to: CGPoint(x: .zero, y: geo.size.height))
                case .downRight:
                    path.move(to: CGPoint.zero)
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        }
    }
}

private extension Color {
    init(hex: Int) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
