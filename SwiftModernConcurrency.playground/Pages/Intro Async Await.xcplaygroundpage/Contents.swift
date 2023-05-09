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

/// Here we are making two url requests which will serially.
/// First, image request will execute then it will suspend the function until we get the response. Once we get the response second metadata request will execute and suspend function until we get the response.

func downloadImageAndMetadata(imageNumber: Int) async throws -> DetailedImage {
    let imageUrl = URL(string: "https://www.andyibanez.com/fairesepages.github.io/tutorials/async-await/part1/\(imageNumber).png")!
    let imageUrlRequest = URLRequest(url: imageUrl)
    let (imageData, imageResponse) = try await URLSession.shared.data(for: imageUrlRequest)
    guard (imageResponse as? HTTPURLResponse)?.statusCode == 200,
          let image = UIImage(data: imageData) else {
        throw ImageDownloadError.badImage
    }
    
    let metadataUrl = URL(string: "https://www.andyibanez.com/fairesepages.github.io/tutorials/async-await/part1/\(imageNumber).json")!
    let metadataUrlRequest = URLRequest(url: metadataUrl)
    let (metadataData, metadataResponse) = try await URLSession.shared.data(for: metadataUrlRequest)
    guard (metadataResponse as? HTTPURLResponse)?.statusCode == 200 else {
        throw ImageDownloadError.invalidMetadata
    }
    
    let jsonDecoder = JSONDecoder()
    let metadata = try jsonDecoder.decode(ImageMetadata.self, from: metadataData)
    
    return DetailedImage(image: image, metadata: metadata)
}

/// Async function can only called in async context and explicitly created Task
/// By default task context inherit from parent context
/// e.g. if we create Task in viewDidLoad method of UIViewController Task context will be Main thread as viewDidLoad function runs on Main Thread.

Task {
    do {
        let detailedImage = try await downloadImageAndMetadata(imageNumber: 1)
    } catch {
        print(error)
    }
}

/// Here we are using async getter properties
var detailedImage: DetailedImage {
    get async throws {
        let detailedImage = try await downloadImageAndMetadata(imageNumber: 1)
        return detailedImage
    }
}

Task {
    do {
        print(try await detailedImage)
    } catch {
        print(error)
    }
}
