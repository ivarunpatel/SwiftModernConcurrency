//: [Previous](@previous)

import Foundation
import UIKit

struct ImageMetadata: Codable {
    let name: String
    let firstAppearance: String
    let year: Int
}

struct DetailedImage {
    let image: UIImage
    let metadata: ImageMetadata
}

enum ImageDownloadError: Error {
    case badImage
    case invalidMetadata
}

/// Continuation is simply what happend after an async call. Everything under await is continuation

// Explicit Continuation

func downloadImageAndMetadata(
    imageNumber: Int,
    completionHandler: @escaping (_ image: DetailedImage?, _ error: Error?) -> Void
) {
    let imageUrl = URL(string: "https://www.andyibanez.com/fairesepages.github.io/tutorials/async-await/part1/\(imageNumber).png")!
    let imageTask = URLSession.shared.dataTask(with: imageUrl) { data, response, error in
        guard let data = data, let image = UIImage(data: data), (response as? HTTPURLResponse)?.statusCode == 200 else {
            completionHandler(nil, ImageDownloadError.badImage)
            return
        }
        let metadataUrl = URL(string: "https://www.andyibanez.com/fairesepages.github.io/tutorials/async-await/part1/\(imageNumber).json")!
        let metadataTask = URLSession.shared.dataTask(with: metadataUrl) { data, response, error in
            guard let data = data, let metadata = try? JSONDecoder().decode(ImageMetadata.self, from: data),  (response as? HTTPURLResponse)?.statusCode == 200 else {
                completionHandler(nil, ImageDownloadError.invalidMetadata)
                return
            }
            let detailedImage = DetailedImage(image: image, metadata: metadata)
            completionHandler(detailedImage, nil)
        }
        metadataTask.resume()
    }
    imageTask.resume()
}

// Checked throwing continuation version
/// There must be continuation call whithin every branch of withCheckedThrowingContinuation
func downloadImageAndMetadata(imageNumber: Int) async throws -> DetailedImage {
    return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<DetailedImage, Error>) in
        downloadImageAndMetadata(imageNumber: imageNumber) { image, error in
            if let detailedImage = image {
                continuation.resume(returning: detailedImage)
            } else {
                continuation.resume(throwing: error!)
            }
        }
    })
}

Task {
    do {
        let detailedImage = try await downloadImageAndMetadata(imageNumber: 1)
    } catch {
        print(error)
    }
}

//: [Next](@next)
