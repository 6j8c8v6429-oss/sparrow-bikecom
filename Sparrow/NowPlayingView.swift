import SwiftUI

/// Replaces the four stat tiles of the reference.
struct NowPlayingView: View {
    @ObservedObject var model: NowPlayingModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("NOW PLAYING")
                Spacer()
                Text("APPLE MUSIC")
            }
            .font(Theme.font(12, weight: .semibold))
            .tracking(1.5)
            .opacity(0.8)

            HStack(spacing: 12) {
                artwork
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.title ?? "Nothing playing")
                        .font(Theme.font(28, weight: .heavy))
                    Text(subtitle)
                        .font(Theme.font(19, weight: .semibold))
                        .opacity(0.8)
                }
                .lineLimit(1)
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                ControlButton(systemName: "backward.fill", label: "Previous", action: model.previous)
                ControlButton(systemName: model.isPlaying ? "pause.fill" : "play.fill",
                              label: model.isPlaying ? "Pause" : "Play",
                              action: model.togglePlayPause)
                    .frame(maxWidth: .infinity)
                    .layoutPriority(1)
                ControlButton(systemName: "forward.fill", label: "Next", action: model.next)
            }
            .disabled(!model.isAuthorized)
        }
        .foregroundStyle(Theme.base)
        .padding(14)
        .background(Theme.ink, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
    }

    private var subtitle: String {
        if !model.isAuthorized { return "Allow Media & Apple Music in Settings" }
        return model.artist ?? "Start something in Apple Music"
    }

    @ViewBuilder
    private var artwork: some View {
        Group {
            if let image = model.artwork {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.base)
            }
        }
        .frame(width: 68, height: 68)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityHidden(true)
    }
}

/// Large, glove-friendly button styled like the dark tiles of the reference.
private struct ControlButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(minWidth: 72, maxWidth: .infinity, minHeight: 56)
                .background(Theme.base, in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
