import MapKit
import SwiftUI

/// Small live map that follows you and turns with your direction, tinted toward the SPARROW palette.
struct RideMapView: View {
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)

    /// Strength of the palette tint over the map. Higher is closer to `Theme.base`, but fainter roads.
    private static let tintOpacity = 0.35

    var body: some View {
        Map(position: $position, interactionModes: [.zoom, .pan]) {
            UserAnnotation {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.ink)
            }
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted,
                            pointsOfInterest: .excludingAll, showsTraffic: false))
        .mapControls {}
        .environment(\.colorScheme, .dark)
        // A plain see-through layer, composited normally. Never use a blend mode here: on device
        // that hides the map tiles and leaves only the arrow.
        .overlay {
            Theme.base
                .opacity(Self.tintOpacity)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .strokeBorder(Theme.ink.opacity(0.4), lineWidth: 1.5)
        }
        .overlay(alignment: .bottomTrailing) {
            if !position.followsUserLocation {
                Button {
                    withAnimation { position = .userLocation(followsHeading: true, fallback: .automatic) }
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.base)
                        .frame(width: 52, height: 52)
                        .background(Theme.ink, in: RoundedRectangle(cornerRadius: 6))
                }
                .padding(10)
                .accessibilityLabel("Follow my location")
            }
        }
    }
}
