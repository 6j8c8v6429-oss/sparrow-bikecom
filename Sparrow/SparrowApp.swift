import SwiftUI

@main
struct SparrowApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

/// Shows the splash on top of the main screen, so the map and GPS already start up underneath.
private struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            ContentView()
            if showSplash {
                SplashView { showSplash = false }
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSplash)
    }
}
