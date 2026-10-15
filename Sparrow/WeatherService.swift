import CoreLocation
import Foundation

struct WeatherCondition: Equatable {
    let symbolName: String
    let description: String

    /// Maps a WMO weather code (as used by Open-Meteo) to an SF Symbol.
    init(wmoCode code: Int, isDay: Bool) {
        let match: (String, String)
        switch code {
        case 0:
            match = (isDay ? "sun.max.fill" : "moon.stars.fill", "Clear")
        case 1, 2:
            match = (isDay ? "cloud.sun.fill" : "cloud.moon.fill", "Partly cloudy")
        case 3:
            match = ("cloud.fill", "Cloudy")
        case 45, 48:
            match = ("cloud.fog.fill", "Fog")
        case 51...57:
            match = ("cloud.drizzle.fill", "Drizzle")
        case 65, 82:
            match = ("cloud.heavyrain.fill", "Heavy rain")
        case 61...67, 80...82:
            match = ("cloud.rain.fill", "Rain")
        case 71...77, 85, 86:
            match = ("cloud.snow.fill", "Snow")
        case 95...99:
            match = ("cloud.bolt.rain.fill", "Thunderstorm")
        default:
            match = ("cloud.fill", "Cloudy")
        }
        symbolName = match.0
        description = match.1
    }
}

/// Current conditions from Open-Meteo (free, no API key or extra entitlement needed).
@MainActor
final class WeatherService: ObservableObject {
    @Published private(set) var condition: WeatherCondition?

    private static let refreshInterval: TimeInterval = 15 * 60
    private static let retryInterval: TimeInterval = 60
    private static let refreshDistance: CLLocationDistance = 5_000

    private var lastFetch: (date: Date, location: CLLocation)?
    private var isFetching = false

    func update(for location: CLLocation) {
        if isFetching { return }
        if let last = lastFetch,
           Date().timeIntervalSince(last.date) < Self.refreshInterval,
           location.distance(from: last.location) < Self.refreshDistance {
            return
        }
        isFetching = true
        Task {
            await fetch(location)
            isFetching = false
        }
    }

    private func fetch(_ location: CLLocation) async {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(location.coordinate.longitude)),
            URLQueryItem(name: "current", value: "weather_code,is_day"),
        ]
        do {
            let (data, _) = try await URLSession.shared.data(from: components.url!)
            let response = try JSONDecoder().decode(Response.self, from: data)
            condition = WeatherCondition(wmoCode: response.current.weatherCode,
                                         isDay: response.current.isDay == 1)
            lastFetch = (Date(), location)
        } catch {
            // Try again in about a minute.
            lastFetch = (Date().addingTimeInterval(Self.retryInterval - Self.refreshInterval), location)
        }
    }

    private struct Response: Decodable {
        struct Current: Decodable {
            let weatherCode: Int
            let isDay: Int

            enum CodingKeys: String, CodingKey {
                case weatherCode = "weather_code"
                case isDay = "is_day"
            }
        }
        let current: Current
    }
}
