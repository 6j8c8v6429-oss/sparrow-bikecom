import SwiftUI

struct ContentView: View {
    @State private var location = LocationManager()
    @StateObject private var weather = WeatherService()
    @StateObject private var nowPlaying = NowPlayingModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ClockView()
                WeatherBadge(condition: weather.condition)
            }
            if nowPlaying.isVisible {
                NowPlayingView(model: nowPlaying)
                    .transition(.scale(scale: 0.92, anchor: .top).combined(with: .opacity))
            }
            // Takes all remaining space, so it grows when the now-playing panel goes away.
            RideMapView()
            SpeedView(location: location)
        }
        .animation(.spring(duration: 0.55, bounce: 0.15), value: nowPlaying.isVisible)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Theme.base.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .onAppear {
            location.onLocation = { [weather] in weather.update(for: $0) }
            location.start()
            keepScreenAwake(true)
        }
        .onChange(of: scenePhase) { _, phase in
            keepScreenAwake(phase == .active)
            if phase == .active { nowPlaying.refresh() }
        }
        .task {
            // Re-check the weather now and then, even when standing still.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                if let current = location.location { weather.update(for: current) }
            }
        }
    }

    private func keepScreenAwake(_ awake: Bool) {
        UIApplication.shared.isIdleTimerDisabled = awake
    }
}

#Preview {
    ContentView()
}
