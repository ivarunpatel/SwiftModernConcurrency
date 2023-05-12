//: [Previous](@previous)

import Foundation

// MARK: - Main Actor

/// `@MainActor` represents main thread. The main actor will perform its synchronization on main dispatch queue.
/// We can add `@MainActor` attribute to function or class
/// When we add `@MainActor` attribute to the class all properties and functions of that class runs on main thread
/// All properties and functions which are part of `@MainActor` should be run on async context
/// We can mark properties and functions as `nonisolated` to not be part of main actor

struct VideoGame {
    let id = UUID()
    let name: String
    let releaseYear: Int
    let developer: String
}

@MainActor
class VideoGameViewModel {
    var videoGames = [VideoGame]()
    
    func loadVideoGames() {
        
    }
    
    nonisolated func someNonIsolatedFunction() {
        
    }
}
Task {
    let viewModel = await VideoGameViewModel()
    viewModel.someNonIsolatedFunction()
}

// MARK: - Global Actor
/// Global actors are declared globally, every objected intrested in adopting them simpty need to append its attribute.

@globalActor
struct MediaActor {
    actor ActorType { }
    
    static let shared: ActorType = ActorType()
}

/// Lets say we want to create one global array which can be written and read from multiple places at once. Thay global variable can be marked with attribute `@MediaActor` and all operations upon it will be run on same thread, making the actor synchronize the state as necessary.

@MediaActor var videoGames: [VideoGame] = []

@MediaActor
func addVideoGame() {
    let valorant = VideoGame(name: "Valorant", releaseYear: 2020, developer: "Riot Games")
    videoGames.append(valorant)
    
    let csgo2 = VideoGame(name: "CS:GO Source 2", releaseYear: 2023, developer: "Valve")
    videoGames.append(csgo2)
}

@MediaActor
func printGameNames() {
    videoGames.forEach {
        print($0.name)
    }
}

Task {
    await addVideoGame()
    await printGameNames()
}

/// When we want to function marked as `@MediaActor` from some other actor e.g. `@MainActor` we need implicitly mark `async`, so we will need to `await` on them.

//: [Next](@next)
