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

func downloadImage(imageNumber: Int) async throws -> UIImage {
    try Task.checkCancellation()
    let imageUrl = URL(string: "https://www.andyibanez.com/fairesepages.github.io/tutorials/async-await/part3/\(imageNumber).png")!
    let imageUrlRequest = URLRequest(url: imageUrl)
    let (imageData, imageResponse) = try await URLSession.shared.data(for: imageUrlRequest)
    guard (imageResponse as? HTTPURLResponse)?.statusCode == 200,
          let image = UIImage(data: imageData) else {
        throw ImageDownloadError.badImage
    }
    return image
}

func downloadMetadata(imageNumber: Int) async throws -> ImageMetadata {
    try Task.checkCancellation()
    let metadataUrl = URL(string: "https://www.andyibanez.com/fairesepages.github.io/tutorials/async-await/part3/\(imageNumber).json")!
    let metadataUrlRequest = URLRequest(url: metadataUrl)
    let (metadataData, metadataResponse) = try await URLSession.shared.data(for: metadataUrlRequest)
    guard (metadataResponse as? HTTPURLResponse)?.statusCode == 200 else {
        throw ImageDownloadError.invalidMetadata
    }
    
    let jsonDecoder = JSONDecoder()
    let metadata = try jsonDecoder.decode(ImageMetadata.self, from: metadataData)
    return metadata
}

/// Detached task are most flexible type of task. We can launch from anywhere, scope lifetime is not scoped, we can cancel them from anywhere manually. They don't inherit anything from their parent task. Not even priority. They are independent from their context.
/// If we cancel detached Task, all child tasks will be mark as cancelled
/// One example of Detached task is downloading image from server and caching them in disk. Caching operation if independent from downloading task cancellation of download task should not cancel caching task as well.
func storeImageInDisk(image: UIImage) async {
    guard let imageData = image.pngData(),
          let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
        return
    }
    let imageURL = cacheURL.appendingPathComponent(UUID().uuidString)
    try? imageData.write(to: imageURL)
}

func downloadImageAndMetadata(imageNumber: Int) async throws -> DetailedImage {
    let image = try await downloadImage(imageNumber: imageNumber)
    Task.detached(priority: .background) {
        await storeImageInDisk(image: image)
    }
    let metadata = try await downloadMetadata(imageNumber: imageNumber)
    let detailedImage = DetailedImage(image: image, metadata: metadata)
    return detailedImage
}

Task {
    do {
        let detailedImage = try await downloadImageAndMetadata(imageNumber: 1)
    } catch {
        print(error)
    }
}

//: [Next](@next)
