//
//  EditItems.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/27.
//

import Foundation

private let logger = getLogger(#file)

struct EditItems {
    let repository: ItemRepository

    // この関数内で .updatedAt などを更新するので、更新後の [Item] を返す必要がある
    func callAsFunction(_ editedItems: [Item], originalItems: [Item]) async throws -> [Item] {
        let itemsToUpdate: [Item]

        if originalItems.isEmpty {
            itemsToUpdate = editedItems
        } else if editedItems.count == originalItems.count {
            itemsToUpdate = zip(originalItems, editedItems).compactMap { original, edited -> Item? in

                if original == edited {
                    return nil
                }

                logger.debug("""
                original item:
                    id: \(original.id)
                    name: \(original.name)
                    category: \(original.category.rawValue)

                edited item:
                    id: \(edited.id)
                    name: \(edited.name)
                    category: \(edited.category.rawValue)
                """)

                return edited
            }
        } else {
            // TODO: [(editItem, originalItem)] の対にすれば、ここは不要になりそう
            throw "originalItems is empty and originalItems.count != editedItems.count"
        }

        let now = Date()
        let updatedItems = itemsToUpdate.map {
            $0
                .copyWith(\.updatedAt, value: now)
        }

        try await repository.update(editedItems)

        return updatedItems
    }
}
