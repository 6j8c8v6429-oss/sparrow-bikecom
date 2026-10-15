import SwiftUI

/// Small heading-up map in the SPARROW palette. Your position is always the centre arrow,
/// and the map turns so that the direction you ride points up. Pinch to zoom.
struct RideMapView: View {
    @ObservedObject var location: LocationManager
    @StateObject private var snapshots = MapSnapshotModel()
    @Environment(\.displayScale) private var displayScale
    @State private var size: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1

    var body: some View {
        Theme.base
            .overlay {
                if let image = snapshots.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(pinch)
                        .id(snapshots.version)
                        .transition(.opacity)
                } else {
                    Text(location.location == nil ? "LOCATING…" : "LOADING MAP…")
                        .font(Theme.font(16, weight: .semibold))
                        .tracking(1.5)
                        .opacity(0.7)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: snapshots.version)
            .overlay {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .background {
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(Theme.base)
                    }
                    .opacity(location.location == nil ? 0 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .strokeBorder(Theme.ink.opacity(0.4), lineWidth: 1.5)
            }
            .contentShape(Rectangle())
            .gesture(
                MagnifyGesture()
                    .updating($pinch) { value, state, _ in state = value.magnification }
                    .onEnded { value in
                        let range = MapSnapshotModel.distanceRange
                        snapshots.distance = min(max(snapshots.distance / value.magnification, range.lowerBound),
                                                 range.upperBound)
                        refresh()
                    }
            )
            .onGeometryChange(for: CGSize.self) { $0.size } action: { newSize in
                size = newSize
                refresh()
            }
            .onChange(of: location.location) { _, _ in refresh() }
            .onChange(of: location.heading) { _, _ in refresh() }
            .onAppear(perform: refresh)
            .accessibilityElement()
            .accessibilityLabel("Map of your surroundings")
    }

    private func refresh() {
        snapshots.update(location: location.location, heading: location.heading,
                         size: size, scale: displayScale)
    }
}
