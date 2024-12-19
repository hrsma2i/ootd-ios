//
//  MigrateOutfits.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/19.
//

import Foundation

struct MigrateOutfits {
    let source: (repository: OutfitRepository, storage: FileStorage)
    let target: (repository: OutfitRepository, storage: FileStorage)

    private var sourceName: (repository: String, storage: String) {
        (String(describing: type(of: source.repository)), source.storage.id)
    }

    private var targetName: (repository: String, storage: String) {
        (String(describing: type(of: target.repository)), target.storage.id)
    }

    func callAsFunction(itemsToJoin: [Item]) async throws -> [(outfit: Outfit, error: Error?)] {
        var results = try await migrateData(itemsToJoin: itemsToJoin)

        if source.storage.id != target.storage.id {
            results = try await migrateImages(results: results)
        } else {
            logger.debug("skipped outfit image migration because source and target storages are the same: \(sourceName.storage)")
        }

        return results
    }

    private func migrateData(itemsToJoin: [Item]) async throws -> [(outfit: Outfit, error: Error?)] {
        // repository.findAll ではなく GetOutfits を使う。なぜなら、 Outfit.imageSource を設定しなければいけないから。 storage に画像があれば設定される。
        let outfits = try await GetOutfits(
            repository: source.repository,
            storage: source.storage
        )(itemsToJoin: itemsToJoin)
        do {
            try await target.repository.save(outfits)
            logger.debug("migrated outfits from \(sourceName.repository) to \(targetName.repository)")
            return outfits.map { ($0, nil) }
        } catch {
            logger.debug("failed to migrated outfits from \(sourceName.repository) to \(targetName.repository): \(error)")
            return outfits.map { ($0, error) }
        }
    }

    private func migrateImages(results: [(outfit: Outfit, error: Error?)]) async throws -> [(outfit: Outfit, error: Error?)] {
        let numberOfImages = results.count

        let results = await results.asyncMap(isParallel: false) { result in
            if result.error != nil {
                return result
            }

            let outfit = result.outfit

            do {
                try await SaveOutfitImage(target: target.storage, source: source.storage)(outfit)
            } catch {
                return (outfit: outfit, error: error)
            }

            return (outfit: outfit, error: nil)
        }

        let numberOfSuccess = results.filter { $0.error == nil }.count
        logger.debug("migrated \(numberOfSuccess)/\(numberOfImages) outfit images from \(sourceName.storage) to \(targetName.storage)")

        return results
    }
}
