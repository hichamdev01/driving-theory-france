import SwiftUI
import UIKit
import AVKit

enum BundledImageLoader {
    /// imagePath is expected as "<country-folder>/<filename.ext>" relative to Content/, e.g. "france/stop.png"
    static func uiImage(for imagePath: String) -> UIImage? {
        let parts = imagePath.split(separator: "/", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        let countryFolder = String(parts[0])
        let filename = String(parts[1])
        let ext = (filename as NSString).pathExtension
        let name = (filename as NSString).deletingPathExtension
        guard
            let url = Bundle.main.url(
                forResource: name, withExtension: ext, subdirectory: "Content/\(countryFolder)/images"
            )
        else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}

enum BundledVideoLoader {
    /// videoPath is expected as "<country-folder>/<filename.ext>" relative to Content/.
    static func url(for videoPath: String) -> URL? {
        let parts = videoPath.split(separator: "/", maxSplits: 1)
        guard parts.count == 2 else { return nil }
        let countryFolder = String(parts[0])
        let filename = String(parts[1])
        let ext = (filename as NSString).pathExtension
        let name = (filename as NSString).deletingPathExtension
        return Bundle.main.url(
            forResource: name, withExtension: ext, subdirectory: "Content/\(countryFolder)/videos"
        )
    }
}

struct BundledQuestionMedia: View {
    let imagePath: String?
    let videoPath: String?

    var body: some View {
        if let videoPath, let url = BundledVideoLoader.url(for: videoPath) {
            BundledVideoPlayer(url: url)
        } else if let imagePath, let uiImage = BundledImageLoader.uiImage(for: imagePath) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

private struct BundledVideoPlayer: View {
    @State private var player: AVPlayer

    init(url: URL) {
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        VideoPlayer(player: player)
            .aspectRatio(16 / 9, contentMode: .fit)
            .onDisappear { player.pause() }
    }
}

/// Renders a road sign's image (or vector fallback). Always paired with the
/// sign's name/meaning as adjacent text, so it is hidden from assistive
/// technologies to avoid a redundant, unlabeled announcement.
struct RoadSignImageView: View {
    let imagePath: String?
    let shape: String
    let color: String
    var size: CGFloat = 56

    var body: some View {
        Group {
            if let imagePath, let uiImage = BundledImageLoader.uiImage(for: imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                RoadSignBadge(shape: shape, color: color, size: size)
            }
        }
        .accessibilityHidden(true)
    }
}
