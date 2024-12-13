//
//  InMemoryItemRepository.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/10.
//

import Foundation



class InMemoryItemRepository: ItemRepository {
    private var items: [Item]

    private var className: String {
        String(describing: Self.self)
    }

    init(items: [Item]) {
        self.items = items
    }

    func findAll() async throws -> [Item] {
        return self.items
    }

    func save(_ items: [Item]) async throws -> [(item: Item, error: (any Error)?)] {
        var results: [(item: Item, error: Error?)] = []

        for newItem in items {
            if let index = self.items.firstIndex(where: { $0.id == newItem.id }) {
                logger.debug("[\(self.className)] update an existing item id=\(newItem.id)")
                self.items[index] = newItem
            } else {
                logger.debug("[\(self.className)] create a new item id=\(newItem.id)")
                self.items.append(newItem)
            }

            results.append((item: newItem, error: nil))
        }

        return results
    }

    func delete(_ items: [Item]) async throws {
        self.items = self.items.filter { existing in
            !items.contains { $0.id == existing.id }
        }
    }
}
