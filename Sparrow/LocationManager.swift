import CoreLocation
import Observation

/// Asks for location permission and keeps the latest position and speed.
///
/// `@Observable` so that only views that read `speed` redraw on each GPS update (about once a
/// second), not the whole screen. The GPS is running for the map anyway, so the speed is free.
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private(set) var location: CLLocation?
    /// Current speed in m/s, or nil when unknown.
    private(set) var speed: CLLocationSpeed?

    /// Called with every new position (used for the weather).
    @ObservationIgnored var onLocation: (@MainActor (CLLocation) -> Void)?

    @ObservationIgnored private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        // Updates keep coming while standing still, so the speed drops back to 0.
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        location = latest
        let newSpeed: CLLocationSpeed? = latest.speed >= 0 ? latest.speed : nil
        if newSpeed != speed { speed = newSpeed }
        // The manager is created on the main thread, so its callbacks arrive there too.
        MainActor.assumeIsolated { onLocation?(latest) }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
