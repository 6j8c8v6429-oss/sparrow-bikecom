import SwiftUI

/// Big 24h clock that replaces the speed readout of the reference.
struct ClockView: View {
    private static let hoursMinutes = formatter("HH:mm")
    private static let seconds = formatter("ss")

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(Self.hoursMinutes.string(from: context.date))
                    .font(Theme.font(124, weight: .heavy))
                    .monospacedDigit()
                Text(Self.seconds.string(from: context.date))
                    .font(Theme.font(30))
                    .monospacedDigit()
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.leading, 14)
            .background(alignment: .leading) { CornerBrackets() }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(context.date, style: .time))
        }
    }

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        return formatter
    }
}

/// The small corner marks to the left of the big number in the reference.
private struct CornerBrackets: View {
    var body: some View {
        VStack {
            bracket
            Spacer()
            bracket.scaleEffect(y: -1)
        }
        .padding(.vertical, 10)
    }

    private var bracket: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 12))
            path.addLine(to: .zero)
            path.addLine(to: CGPoint(x: 8, y: 0))
        }
        .stroke(Theme.ink, lineWidth: 4)
        .frame(width: 8, height: 12)
    }
}
