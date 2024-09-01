//
//  ItemStore.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/14.
//

import Foundation

private let logger = getLogger(#file)

class ItemStore: ObservableObject {
    var dataSource: ItemDataSource

    @Published var items: [Item] = []

    @MainActor
    init(_ dataSourceType: DataSourceType = .sample) {
        switch dataSourceType {
        case .sample:
            dataSource = SampleItemDataSource()
        case .swiftData:
            dataSource = SwiftDataItemDataSource.shared
        }
    }

    @MainActor
    func fetch() async throws {
        logger.debug("fetch items")
        items = try await dataSource.fetch()
    }

    @MainActor
    func create(_ items: [Item]) async throws {
        Task {
            let itemsWithID = try await dataSource.create(items)

            DispatchQueue.main.async {
                self.items.append(contentsOf: itemsWithID)
            }
        }
    }

    func update(_ editedItems: [Item], originalItems: [Item] = []) async throws {
        // originalItems と比較して、フィールドが更新された Item のみ更新する

        let itemsToUpdate: [Item]

        if originalItems.isEmpty {
            itemsToUpdate = editedItems
        } else if editedItems.count == originalItems.count {
            itemsToUpdate = zip(originalItems, editedItems).compactMap { original, edited in

                if original == edited {
                    return nil
                }

                logger.debug("""
                original item:
                    id: \(original.id ?? "nil")
                    category: \(original.category.rawValue)

                edited item:
                    id: \(edited.id ?? "nil")
                    category: \(edited.category.rawValue)
                """)

                return edited
            }
        } else {
            logger.error("originalItems is empty and originalItems.count != editedItems.count")
            return
        }

        for item in itemsToUpdate {
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                logger.debug("update local item at index=\(index)")
                DispatchQueue.main.async {
                    self.items[index] = item
                }
            }
        }

        Task {
            try await dataSource.update(itemsToUpdate)
        }
    }

    func filter(_ items: [Item], by filter: ItemFilter) -> [Item] {
        var newItems: [Item] = items

        if let category = filter.category {
            newItems = newItems.filter { $0.category == category }
        }

        return newItems
    }

    func delete(_ items: [Item]) async throws {
        DispatchQueue.main.async {
            self.items.removeAll { item in items.contains { item.id == $0.id } }
        }
        Task {
            try await dataSource.delete(items)
        }
    }
}
