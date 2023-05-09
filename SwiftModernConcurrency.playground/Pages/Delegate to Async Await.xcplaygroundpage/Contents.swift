//: [Previous](@previous)

import Foundation

protocol ItemSelectionDelegate: AnyObject {
    func didSelectItem(item: String)
}

class ItemListController {
    
    let items: [String] = ["Item1", "Item2", "Item3"]
    weak var delegate: ItemSelectionDelegate?
    
    func selectItem(at index: Int) {
        delegate?.didSelectItem(item: items[index])
    }
}

class ItemSelectionViewController: ItemSelectionDelegate {
    private typealias ItemCheckedContinuation = CheckedContinuation<String, Never>
    
    private let itemListViewController = ItemListController()
    private var itemContinuation: ItemCheckedContinuation?
    
    func setup() {
        itemListViewController.delegate = self
    }
    
    func pickItem(at index: Int) async -> String {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.itemListViewController.selectItem(at: index)
        }
        // Create CheckedContinuation and hold the reference
        return await withCheckedContinuation({ (continuation: ItemCheckedContinuation) in
            self.itemContinuation = continuation
        })
    }
    
    func didSelectItem(item: String) {
        // Resume continuation with item
        itemContinuation?.resume(returning: item)
        itemContinuation = nil // Setting nil so only called once
    }
}

Task {
    let itemSelectionViewController = ItemSelectionViewController()
    itemSelectionViewController.setup()
    let selectedItem = await itemSelectionViewController.pickItem(at: 1)
}

//: [Next](@next)
