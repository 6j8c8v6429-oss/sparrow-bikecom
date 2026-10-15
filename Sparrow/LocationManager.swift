import CoreLocation

/// Asks for location permission and publishes the latest position and travel direction.
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var location: CLLocation?
    /// Direction of travel in degrees from north: GPS course while riding, compass when standing still.
    @Published private(set) var heading: CLLocationDirection = 0

    /// Below this speed (m/s) the GPS course is unreliable, so the compass is used instead.
    private static let minimumCourseSpeed: CLLocationSpeed = 1.5

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = 5
        manager.headingFilter = 10
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            manager.startUpdatingHeading()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        location = latest
        if latest.course >= 0, latest.speed >= Self.minimumCourseSpeed {
            heading = latest.course
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if let speed = location?.speed, speed >= Self.minimumCourseSpeed { return }
        heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
