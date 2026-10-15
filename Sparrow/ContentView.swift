import SwiftUI

struct ContentView: View {
    @StateObject private var location = LocationManager()
    @StateObject private var weather = WeatherService()
    @StateObject private var nowPlaying = NowPlayingModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ClockView()
                WeatherBadge(condition: weather.condition)
            }
            NowPlayingView(model: nowPlaying)
            RideMapView()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(Theme.base.ignoresSafeArea())
        .foregroundStyle(Theme.ink)
        .onAppear {
            location.start()
            keepScreenAwake(true)
        }
        .onChange(of: scenePhase) { _, phase in
            keepScreenAwake(phase == .active)
            if phase == .active { nowPlaying.refresh() }
        }
        .onReceive(location.$location.compactMap { $0 }) { weather.update(for: $0) }
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
