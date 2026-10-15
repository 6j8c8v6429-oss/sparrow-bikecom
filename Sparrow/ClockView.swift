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
