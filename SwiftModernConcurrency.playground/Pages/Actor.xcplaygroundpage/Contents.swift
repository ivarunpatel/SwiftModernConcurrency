//: [Previous](@previous)

import Foundation
import UIKit

/// Actor solve data races by providing synchronization for mutable state automatically, they isolate their state from rest of the program. This means nobody can modify the shared state unless they go through the actor itself.
/// Actors are references type same as class, only difference is they don't support.

/// All actors public interface are automatic made async for its consumers. This allows us to safely intrect with actors, because using the await keyword will suspend execution until code is notified that is can go into the actor next and do its job.
actor Counter {
    var count = 0
    
    func increment() -> Int {
        count += 1
        return count
    }
    
    func reset() {
        count = 0
    }
    
    func functionWithoutAwait() {
        // Everything called within the actor is synchronous. No need to write `await` keyword before function call within the actor.
        reset()
    }
}

// MARK: - Example - 1

let counter = Counter()
// print(counter.count)  // We cannot directly access or mutate actor property outside of actor
Task.detached {
    print(await counter.increment())
}

Task.detached {
    print(await counter.increment())
}

// MARK: - Example - 2

actor ImageDownloader {
    enum ImageStatus {
        case downloading(task: Task<UIImage, Error>)
        case downloaded(image: UIImage)
    }
    
    private var cache: [URL: ImageStatus] = [:]
    
    func image(from url: URL) async throws -> UIImage {
        if let imageStatus = cache[url] {
            switch imageStatus {
            case .downloading(let task):
                print("Returned from downloading switch case")
                return try await task.value
            case .downloaded(let image):
                print("Returned from downloaded cached version from switch case")
                return image
            }
        }
        
        let task = Task {
            try await downloadImage(url: url)
        }
        
        // Mutation from same task and after suspension
        cache[url] = .downloading(task: task)
        
        do {
            let image = try await task.value
            cache[url] = .downloaded(image: image)
            return image
        } catch {
            cache[url] = nil
            throw error
        }
    }
}

enum ImageDownloadError: Error {
    case badImage
    case invalidMetadata
}

func downloadImage(url: URL) async throws -> UIImage {
    try Task.checkCancellation()
    let imageUrlRequest = URLRequest(url: url)
    let (imageData, imageResponse) = try await URLSession.shared.data(for: imageUrlRequest)
    guard (imageResponse as? HTTPURLResponse)?.statusCode == 200,
          let image = UIImage(data: imageData) else {
        throw ImageDownloadError.badImage
    }
    return image
}

let imageDownloader = ImageDownloader()

Task {
    do {
        let imageURL = URL(string: "https://www.learningcontainer.com/wp-content/uploads/2020/07/Large-Sample-Image-download-for-Testing.jpg")!
        async let firstImage = imageDownloader.image(from: imageURL)
        async let secondImage = imageDownloader.image(from: imageURL)
        print(try await firstImage)
        print(try await secondImage)
    } catch {
        print(error)
    }
}
/// In above example we are downloading same image at same time. So when we enter in `image(from:` function we are first checking image state then if it is require we are downloading the image


//: [Next](@next)
