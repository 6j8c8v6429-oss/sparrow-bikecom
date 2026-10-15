import MediaPlayer
import UIKit

/// What's playing in Apple Music, with transport controls.
///
/// iOS only exposes the system Music app's player to other apps. Audio from Podcasts,
/// Spotify, etc. can't be read by third-party apps at all, so the panel only covers Apple Music.
@MainActor
final class NowPlayingModel: ObservableObject {
    @Published private(set) var title: String?
    @Published private(set) var artist: String?
    @Published private(set) var artwork: UIImage?
    @Published private(set) var isPlaying = false
    @Published private(set) var isAuthorized = MPMediaLibrary.authorizationStatus() == .authorized
    /// Whether the panel should be on screen: while playing, and for a short while after pausing
    /// so you can still resume.
    @Published private(set) var isVisible = false

    /// How long the panel stays after pausing before it slides away.
    private static let pausedGracePeriod: Duration = .seconds(15)

    private let player = MPMusicPlayerController.systemMusicPlayer
    private var observers: [NSObjectProtocol] = []
    private var hideTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?
    private var currentItemID: MPMediaEntityPersistentID?

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

        // The Music app doesn't always send notifications (e.g. when it is closed), so check often.
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self else { return }
                self.refresh()
            }
        }
    }

    func refresh() {
        let item = player.nowPlayingItem
        if item?.persistentID != currentItemID {
            currentItemID = item?.persistentID
            title = item?.title
            artist = item?.artist ?? item?.albumTitle
            artwork = item?.artwork?.image(at: CGSize(width: 200, height: 200))
        }
        let state = player.playbackState
        isPlaying = state == .playing
        updateVisibility(hasItem: item != nil, state: state)
    }

    private func updateVisibility(hasItem: Bool, state: MPMusicPlaybackState) {
        if hasItem && state == .playing {
            hideTask?.cancel()
            hideTask = nil
            isVisible = true
        } else if !hasItem || state == .stopped {
            hideTask?.cancel()
            hideTask = nil
            isVisible = false
        } else if isVisible && hideTask == nil {
            hideTask = Task { [weak self] in
                try? await Task.sleep(for: Self.pausedGracePeriod)
                guard !Task.isCancelled, let self else { return }
                self.hideTask = nil
                if !self.isPlaying { self.isVisible = false }
            }
        }
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
