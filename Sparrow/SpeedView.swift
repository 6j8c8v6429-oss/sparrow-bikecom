import CoreLocation
import SwiftUI

/// Small speed readout under the map.
struct SpeedView: View {
    let location: LocationManager

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            Spacer()
            Text(speedText)
                .font(Theme.font(26, weight: .heavy))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text("KM/H")
                .font(Theme.font(13, weight: .semibold))
                .tracking(1.5)
                .opacity(0.8)
        }
        .animation(.easeOut(duration: 0.3), value: speedText)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Speed \(speedText) kilometres per hour")
    }

    private var speedText: String {
        guard let speed = location.speed else { return "--" }
        let kmh = speed * 3.6
        // GPS jitter reads as a little speed while standing still.
        return kmh < 1 ? "0.0" : String(format: "%.1f", kmh)
    }
}
