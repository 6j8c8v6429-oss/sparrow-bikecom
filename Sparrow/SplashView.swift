import SwiftUI

/// Short opening animation: the SPARROW arrow, centred on screen, with a bar that fills up quickly.
struct SplashView: View {
    let onFinished: () -> Void

    @State private var progress: CGFloat = 0

    private static let fillDuration = 1.2
    private static let barWidth: CGFloat = 140

    var body: some View {
        VStack(spacing: 36) {
            SparrowArrow()
                .fill(Theme.ink)
                .frame(width: 84, height: 100)

            Capsule()
                .fill(Theme.ink.opacity(0.25))
                .frame(width: Self.barWidth, height: 6)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Theme.ink)
                        .frame(width: Self.barWidth * progress)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.base.ignoresSafeArea())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loading SPARROW")
        .task {
            withAnimation(.easeInOut(duration: Self.fillDuration)) { progress = 1 }
            try? await Task.sleep(for: .seconds(Self.fillDuration + 0.15))
            onFinished()
        }
    }
}

/// The navigation arrow from the app icon.
struct SparrowArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.80))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
