#!/usr/bin/env swift

import Foundation
import ImageIO
import Vision

private struct RecognizedLine {
    let text: String
    let x: CGFloat
    let y: CGFloat
}

private func recognize(path: String) throws -> [String] {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let source = CGImageSourceCreateWithURL(url, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        throw NSError(domain: "AuthoringCardOCR", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Unable to load image: \(path)",
        ])
    }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    // Automatic language detection avoids a command-line Vision failure on
    // hosts where the optional language-correction model is not installed.
    request.automaticallyDetectsLanguage = true
    request.usesLanguageCorrection = false
    try VNImageRequestHandler(cgImage: image, options: [:]).perform([request])

    let lines = (request.results ?? []).compactMap { observation -> RecognizedLine? in
        guard let text = observation.topCandidates(1).first?.string else { return nil }
        return RecognizedLine(text: text, x: observation.boundingBox.minX, y: observation.boundingBox.maxY)
    }
    return lines.sorted {
        if abs($0.y - $1.y) > 0.012 { return $0.y > $1.y }
        return $0.x < $1.x
    }.map(\.text)
}

let paths = Array(CommandLine.arguments.dropFirst())
guard !paths.isEmpty else {
    FileHandle.standardError.write(Data("Usage: ocr-authoring-cards.swift <image> [...]\n".utf8))
    exit(2)
}

for path in paths {
    do {
        let object: [String: Any] = ["path": path, "lines": try recognize(path: path)]
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        print(String(decoding: data, as: UTF8.self))
    } catch {
        let object: [String: Any] = ["path": path, "error": error.localizedDescription]
        let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
        print(String(decoding: data, as: UTF8.self))
    }
}
