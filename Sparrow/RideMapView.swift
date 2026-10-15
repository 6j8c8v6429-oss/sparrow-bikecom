import MapKit
import SwiftUI

/// Small map that follows you, tinted to the SPARROW palette.
struct RideMapView: View {
    @State private var position: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)

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
        // Recolour the map into the grey-blue of the palette, keeping its light/dark detail.
        .overlay {
            Theme.base
                .blendMode(.color)
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
