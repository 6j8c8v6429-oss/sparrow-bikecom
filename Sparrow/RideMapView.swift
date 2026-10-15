import MapKit
import SwiftUI

/// Small live 3D map that follows you and turns with the direction you're facing,
/// tinted toward the SPARROW palette.
struct RideMapView: View {
    @State private var isFollowing = true
    @State private var recenterRequest = 0

    /// Strength of the palette tint over the map. Higher is closer to `Theme.base`, but fainter roads.
    fileprivate static let tintOpacity = 0.35

    var body: some View {
        FollowingMap(isFollowing: $isFollowing, recenterRequest: recenterRequest)
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
                if !isFollowing {
                    Button {
                        recenterRequest += 1
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Theme.base)
                            .frame(width: 52, height: 52)
                            .background(Theme.ink, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(10)
                    .accessibilityLabel("Follow my location")
                    .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.2), value: isFollowing)
    }
}

private extension UIColor {
    var rgba: (r: CGFloat, g: CGFloat, b: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }
}

/// MKMapView does the follow-and-rotate itself, which stays smoother than moving the camera by hand,
/// and it keeps a tilted (3D) camera while following. SwiftUI's `Map` can't set a tilt when following.
private struct FollowingMap: UIViewRepresentable {
    @Binding var isFollowing: Bool
    let recenterRequest: Int

    /// Camera tilt in degrees (0 is straight down) and distance in metres.
    fileprivate static let pitch: CGFloat = 65
    fileprivate static let distance: CLLocationDistance = 650

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.overrideUserInterfaceStyle = .dark
        let configuration = MKStandardMapConfiguration(elevationStyle: .realistic, emphasisStyle: .muted)
        configuration.pointOfInterestFilter = .excludingAll
        configuration.showsTraffic = false
        map.preferredConfiguration = configuration
        map.showsUserLocation = true
        map.showsCompass = false
        map.showsScale = false
        map.isPitchEnabled = true
        map.isRotateEnabled = true
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        let coordinator = context.coordinator
        coordinator.isFollowing = $isFollowing
        if recenterRequest != coordinator.handledRecenterRequest {
            coordinator.handledRecenterRequest = recenterRequest
            coordinator.startFollowing(map)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(isFollowing: $isFollowing) }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var isFollowing: Binding<Bool>
        var handledRecenterRequest = 0
        private var hasStarted = false

        init(isFollowing: Binding<Bool>) { self.isFollowing = isFollowing }

        /// Tilts the camera over your position, then follows you and turns with your heading.
        func startFollowing(_ map: MKMapView) {
            guard let coordinate = map.userLocation.location?.coordinate else { return }
            let camera = MKMapCamera(lookingAtCenter: coordinate,
                                     fromDistance: map.camera.centerCoordinateDistance > 0
                                        ? min(map.camera.centerCoordinateDistance, 3_000)
                                        : FollowingMap.distance,
                                     pitch: FollowingMap.pitch,
                                     heading: map.camera.heading)
            map.setCamera(camera, animated: true)
            map.setUserTrackingMode(.followWithHeading, animated: true)
        }

        func mapView(_ map: MKMapView, didUpdate userLocation: MKUserLocation) {
            // First position: start in 3D, centred on you, facing the way you face.
            guard !hasStarted, userLocation.location != nil else { return }
            hasStarted = true
            let camera = MKMapCamera(lookingAtCenter: userLocation.coordinate,
                                     fromDistance: FollowingMap.distance,
                                     pitch: FollowingMap.pitch,
                                     heading: map.camera.heading)
            map.setCamera(camera, animated: false)
            map.setUserTrackingMode(.followWithHeading, animated: true)
        }

        func mapView(_ map: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
            isFollowing.wrappedValue = mode != .none
        }

        /// The arrow is drawn by hand rather than from an SF Symbol, which turned out black on the map.
        /// The tint overlay sits on top of the whole map and would dull the arrow, so its colour is
        /// brightened to cancel that out and show as exactly `Theme.ink` on screen.
        private static let arrowImage: UIImage = {
            func channel(_ ink: CGFloat, _ base: CGFloat) -> CGFloat {
                let opacity = CGFloat(RideMapView.tintOpacity)
                return min(max((ink - opacity * base) / (1 - opacity), 0), 1)
            }
            let ink = UIColor(Theme.ink).rgba, base = UIColor(Theme.base).rgba
            let color = UIColor(red: channel(ink.r, base.r), green: channel(ink.g, base.g),
                                blue: channel(ink.b, base.b), alpha: 1)
            let size = CGSize(width: 34, height: 40)
            return UIGraphicsImageRenderer(size: size).image { _ in
                let path = UIBezierPath()
                path.move(to: CGPoint(x: size.width / 2, y: 1))
                path.addLine(to: CGPoint(x: size.width - 2, y: size.height - 2))
                path.addLine(to: CGPoint(x: size.width / 2, y: size.height * 0.78))
                path.addLine(to: CGPoint(x: 2, y: size.height - 2))
                path.close()
                path.lineJoinStyle = .round
                path.lineWidth = 3
                color.setFill()
                color.setStroke()
                path.fill()
                path.stroke()
            }
        }()

        /// Your position is drawn as an arrow in the SPARROW colour.
        func mapView(_ map: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is MKUserLocation else { return nil }
            let id = "sparrow.user"
            let view = map.dequeueReusableAnnotationView(withIdentifier: id)
                ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.image = Self.arrowImage
            view.canShowCallout = false
            view.isEnabled = false
            return view
        }
    }
}
