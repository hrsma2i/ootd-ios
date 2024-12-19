//
//  MigrateItems.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/18.
//

import Foundation

struct MigrateItems {
    let source: (repository: ItemRepository, storage: FileStorage)
    let target: (repository: ItemRepository, storage: FileStorage)

    private var sourceName: (repository: String, storage: String) {
        (String(describing: type(of: source.repository)), source.storage.id)
    }

    private var targetName: (repository: String, storage: String) {
        (String(describing: type(of: target.repository)), target.storage.id)
    }

    func callAsFunction() async throws -> [(item: Item, error: Error?)] {
        var results = try await migrateData()

        if source.storage.id != target.storage.id {
            results = try await migrateImages(results: results)
        } else {
            logger.debug("skipped item image migration because source and target storages are the same: \(sourceName.storage)")
        }

        return results
    }

    private func migrateData() async throws -> [(item: Item, error: Error?)] {
        let items = try await source.repository.findAll()
        let results = try await target.repository.save(items)
        let numberOfSuccess = results.filter { $0.error == nil }.count
        logger.debug("migrated \(numberOfSuccess)/\(items.count) items from \(sourceName.repository) to \(targetName.repository)")
        for result in results {
            if result.error != nil {
                logger.critical("failed to migrate item: \(result.item.id)")
            }
        }
        return results
    }

    private func migrateImages(results: [(item: Item, error: Error?)]) async throws -> [(item: Item, error: Error?)] {
        let numberOfImages = results.count

        let results = await results.asyncMap(isParallel: false) { result in
            if result.error != nil {
                return result
            }

            let item = result.item

            do {
                try await SaveItemImage(target: target.storage, source: source.storage)(item)
            } catch {
                return (item: item, error: error)
            }

            return (item: item, error: nil)
        }

        let numberOfSuccess = results.filter { $0.error == nil }.count
        logger.debug("migrated \(numberOfSuccess)/\(numberOfImages) item images from \(sourceName.storage) to \(targetName.storage)")

        return results
    }
}
