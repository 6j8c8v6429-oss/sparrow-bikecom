import SwiftUI

/// The little box next to the clock, showing the current weather as an icon.
struct WeatherBadge: View {
    let condition: WeatherCondition?

    var body: some View {
        Image(systemName: condition?.symbolName ?? "cloud")
            .symbolRenderingMode(.monochrome)
            .font(.system(size: 30, weight: .bold))
            .foregroundStyle(Theme.base)
            .frame(width: 60, height: 72)
            .background(Theme.ink, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .padding(.top, 16)
            .accessibilityLabel(condition?.description ?? "Weather unavailable")
    }
}
