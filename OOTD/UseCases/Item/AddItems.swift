//
//  AddItems.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/27.
//

import Foundation

struct AddItems {
    let repository: ItemRepository
    let storage: FileStorage

    func callAsFunction(_ items: [Item]) async throws -> [(item: Item, error: Error?)] {
        let saveResults = try await repository.save(items)

        let saveImage = SaveItemImage(storage: storage)
        let imageSaveResults: [(item: Item, error: Error?)] = await saveResults.asyncMap(isParallel: false) { result in
            if result.error != nil {
                return result
            }

            do {
                try await saveImage(result.item)
                return (item: result.item, error: nil)
            } catch {
                return (item: result.item, error: error)
            }
        }

        let failures: [Item] = imageSaveResults.compactMap {
            $0.error != nil ? $0.item : nil
        }

        if !failures.isEmpty {
            await rollback(failures)
        }

        return imageSaveResults
    }

    private func rollback(_ items: [Item]) async {
        await safeDo {
            try await repository.delete(items)
        }

        for item in items {
            await safeDo {
                try await storage.remove(at: item.imagePath)
            }

            await safeDo {
                try await storage.remove(at: item.thumbnailPath)
            }
        }
    }
}
