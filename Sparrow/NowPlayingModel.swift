import MediaPlayer
import UIKit

/// What's playing in Apple Music, with transport controls.
///
/// iOS only exposes the system Music app's player to other apps. Audio from Podcasts,
/// Spotify, etc. can't be read, so for those the panel shows "Nothing playing".
@MainActor
final class NowPlayingModel: ObservableObject {
    @Published private(set) var title: String?
    @Published private(set) var artist: String?
    @Published private(set) var artwork: UIImage?
    @Published private(set) var isPlaying = false
    @Published private(set) var isAuthorized = MPMediaLibrary.authorizationStatus() == .authorized

    private let player = MPMusicPlayerController.systemMusicPlayer
    private var observers: [NSObjectProtocol] = []

    init() {
        player.beginGeneratingPlaybackNotifications()
        let center = NotificationCenter.default
        for name in [Notification.Name.MPMusicPlayerControllerNowPlayingItemDidChange,
                     .MPMusicPlayerControllerPlaybackStateDidChange] {
            observers.append(center.addObserver(forName: name, object: player, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            })
        }

        MPMediaLibrary.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.isAuthorized = status == .authorized
                self?.refresh()
            }
        }
        refresh()
    }

    func refresh() {
        let item = player.nowPlayingItem
        title = item?.title
        artist = item?.artist ?? item?.albumTitle
        artwork = item?.artwork?.image(at: CGSize(width: 200, height: 200))
        isPlaying = player.playbackState == .playing
    }

    func togglePlayPause() {
        if isPlaying { player.pause() } else { player.play() }
    }

    func next() { player.skipToNextItem() }

    /// Restarts the track, or goes to the previous one when near the start (like the Music app).
    func previous() {
        if player.currentPlaybackTime > 3 {
            player.skipToBeginning()
        } else {
            player.skipToPreviousItem()
        }
    }
}
