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

/// Async let will allows us to execute code concurrently. We can use structure concurrency where there is no depedencies between tasks.
/// Image and Metadata download task will begin execution on paralled and suspend the function on return statement
/// Suppose `downloadMetadata` fails and `downloadImage` is downloading a big image
/// since `downloadMetadata` failed, `downloadImage` will be marked as `cancelled`
/// Marking a task as `cancelled` does not actually mean that the task is cancelled. Instead, it simply notifies the task that its results are no longer needed. All the child tasks and their descendants will be cancelled when their parent is cancelled.

func downloadImageAndMetadata(imageNumber: Int) async throws -> DetailedImage {
    async let image = downloadImage(imageNumber: imageNumber)
    async let metadata = downloadMetadata(imageNumber: imageNumber)
    return try DetailedImage(image: await image, metadata: await metadata)
}

Task {
    do {
        let detailedImage = try await downloadImageAndMetadata(imageNumber: 1)
    } catch {
        print(error)
    }
}

//: [Next](@next)
