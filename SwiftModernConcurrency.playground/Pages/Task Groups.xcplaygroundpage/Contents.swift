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

/// A Task Group is a form of structured concurrency designed to provide a dynamic amount of concurrency. With it, we can launch multiple tasks, launch them in a group, and have them execute all at the same time.
/// When we add task to group it execute immediately in any order, so we need to design our code in such way there is no depedencies in child tasks.
/// To introduce data safety, Swift implements the concept of a @Sendable closure. Whenever we create a Task, the body is a @Sendable closure, and this closure has the following properties:
/// - Cannot capture mutable variables.
/// - We can capture value types, actors, classes or other objects that implement their own synchronization.
/// We can also use addTaskUnlessCancelled() which will avoid adding task if group is cancelled
func downloadMultipleImagesWithMetadata(imageNumbers: Int...) async throws -> [DetailedImage] {
    var detailedImages: [DetailedImage] = []
    try await withThrowingTaskGroup(of: DetailedImage.self, body: { group in
        for imageNumber in imageNumbers {
            group.addTask(priority: imageNumber == 3 ? .high : nil) {
                async let detailedImage = downloadImageAndMetadata(imageNumber: imageNumber)
                return try await detailedImage
            }
        }
        
        for try await image in group {
            detailedImages.append(image)
        }
    })
    return detailedImages
}

Task {
    do {
        let detailedImages = try await downloadMultipleImagesWithMetadata(imageNumbers: 1,2,3)
    } catch {
        print(error)
    }
}

//: [Next](@next)
