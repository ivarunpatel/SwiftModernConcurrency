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

func downloadImageAndMetadata(imageNumber: Int) async throws -> DetailedImage {
    async let image = downloadImage(imageNumber: imageNumber)
    async let metadata = downloadMetadata(imageNumber: imageNumber)
    return try DetailedImage(image: await image, metadata: await metadata)
}

/// Unstructured concurrency is useful when we want to launch task from non-async contexts. They can outlive their scopes.
/// In unstructured concurrency we can start and store task into variable. Which allow us to get result somewhere else and also cancel from somewhwre else. e.g Loading `UIImage` in `UITableViewCell` and cancelling when `UITableViewCell` is no longer visible

var downloadTask: Task<DetailedImage, Error>? {
    didSet {
        if downloadTask == nil {
            print("Completed")
        } else {
            print("Downloading")
        }
    }
}

func beginImageDownload(imageNumber: Int) {
    downloadTask = Task {
        try await downloadImageAndMetadata(imageNumber: imageNumber)
    }
}

func downloadImage() async {
    beginImageDownload(imageNumber: 1)
    do {
        if let detailedImage = try await downloadTask?.value {
            print(detailedImage.metadata.name)
        }
    } catch {
        print(error)
    }
    downloadTask = nil
}

func cancelImageDownload() {
    downloadTask?.cancel()    
}

Task {
    await downloadImage()
}

//: [Next](@next)
