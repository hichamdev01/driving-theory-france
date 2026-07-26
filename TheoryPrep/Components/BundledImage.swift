import SwiftUI
import UIKit

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

struct RoadSignImageView: View {
    let imagePath: String?
    let shape: String
    let color: String
    var size: CGFloat = 56

    var body: some View {
        if let imagePath, let uiImage = BundledImageLoader.uiImage(for: imagePath) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            RoadSignBadge(shape: shape, color: color, size: size)
        }
    }
}
