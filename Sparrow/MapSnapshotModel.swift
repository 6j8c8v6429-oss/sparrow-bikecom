import CoreImage
import MapKit
import UIKit

/// Renders the map as a still image with MapKit's snapshotter and recolours it into the
/// SPARROW palette. The live `Map` view can't be recoloured reliably, but a snapshot can.
@MainActor
final class MapSnapshotModel: ObservableObject {
    @Published private(set) var image: UIImage?
    /// Bumped for every new image, so the view can cross-fade between them.
    @Published private(set) var version = 0

    /// Camera distance in metres; changed by pinching the map.
    var distance: CLLocationDistance = 900

    static let distanceRange: ClosedRange<CLLocationDistance> = 250...6_000

    private struct Request: Equatable {
        var location: CLLocation
        var heading: CLLocationDirection
        var size: CGSize
        var scale: CGFloat
        var distance: CLLocationDistance
    }

    private var lastRendered: (request: Request, date: Date)?
    private var queued: Request?
    private var isRendering = false

    private static let ciContext = CIContext()

    func update(location: CLLocation?, heading: CLLocationDirection, size: CGSize, scale: CGFloat) {
        guard let location, size.width > 1, size.height > 1 else { return }
        let request = Request(location: location, heading: heading, size: size, scale: scale, distance: distance)
        guard needsRender(request) else { return }
        if isRendering {
            queued = request
        } else {
            render(request)
        }
    }

    /// Re-renders only when the view would visibly change, to save battery and data.
    private func needsRender(_ request: Request) -> Bool {
        guard let (last, date) = lastRendered else { return true }
        if last.size != request.size || last.distance != request.distance || last.scale != request.scale {
            return true
        }
        guard Date().timeIntervalSince(date) >= 1 else { return false }
        let moved = request.location.distance(from: last.location)
        let turned = abs(angleDifference(request.heading, last.heading))
        return moved >= request.distance / 60 || turned >= 10
    }

    private func render(_ request: Request) {
        isRendering = true
        lastRendered = (request, Date())

        let options = MKMapSnapshotter.Options()
        let configuration = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
        configuration.pointOfInterestFilter = .excludingAll
        configuration.showsTraffic = false
        options.preferredConfiguration = configuration
        options.camera = MKMapCamera(lookingAtCenter: request.location.coordinate,
                                     fromDistance: request.distance,
                                     pitch: 0,
                                     heading: request.heading)
        options.size = request.size
        options.traitCollection = UITraitCollection { traits in
            traits.userInterfaceStyle = .dark
            traits.displayScale = request.scale
        }

        MKMapSnapshotter(options: options).start { [weak self] snapshot, _ in
            Task { @MainActor in
                guard let self else { return }
                if let snapshot, let tinted = Self.tint(snapshot.image) {
                    self.image = tinted
                    self.version += 1
                }
                self.isRendering = false
                if let next = self.queued {
                    self.queued = nil
                    if self.needsRender(next) { self.render(next) }
                }
            }
        }
    }

    // MARK: Recolouring

    /// Map brightness range that gets stretched over base → ink. The dark map's land sits near
    /// the low end and its roads and labels near the high end. Tweak these to taste.
    private static let darkLevel: CGFloat = 0.12
    private static let lightLevel: CGFloat = 0.55

    /// Turns the dark map into a two-tone map: land becomes `Theme.base`, roads and labels `Theme.ink`.
    private static func tint(_ image: UIImage) -> UIImage? {
        guard let input = CIImage(image: image) else { return nil }
        let gain = 1 / (lightLevel - darkLevel)
        let bias = -darkLevel * gain
        let output = input
            .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0])
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: gain, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: gain, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: gain, w: 0),
                "inputBiasVector": CIVector(x: bias, y: bias, z: bias, w: 0),
            ])
            .applyingFilter("CIColorClamp")
            .applyingFilter("CIFalseColor", parameters: [
                "inputColor0": CIColor(color: UIColor(Theme.base)),
                "inputColor1": CIColor(color: UIColor(Theme.ink)),
            ])
        guard let cgImage = ciContext.createCGImage(output, from: input.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
    }

    private func angleDifference(_ a: Double, _ b: Double) -> Double {
        (a - b + 540).truncatingRemainder(dividingBy: 360) - 180
    }
}
