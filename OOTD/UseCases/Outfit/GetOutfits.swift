//
//  GetOutfits.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/27.
//

import Foundation

struct GetOutfits {
    let repository: OutfitRepository
    let storage: FileStorage

    // ItemStore.items から直接渡せるように [Item] にしている。 ItemRepository を引数にしない理由:
    //   1. ItemStore での取得と合わせて二重で全ての Item を取得してしまうから
    //   2. 結局 InMemoryRepository しか使わないので
    @MainActor
    func callAsFunction(itemsToJoin: [Item]) async throws -> [Outfit] {
        var outfits = try await repository.findAll()
        // TODO: 順序保証されてれば isParallel: true にしたほうが初回読み込みが速そう
        outfits = await outfits.asyncMap(isParallel: false) {
            await setImageSourceIfExists($0)
        }

        if repository.shouldClientSideJoin {
            outfits = join(outfits, with: itemsToJoin)
        }

        return outfits
    }

    private func setImageSourceIfExists(_ outfit: Outfit) async -> Outfit {
        var outfit = outfit

        let imageExists = (try? await storage.exists(at: outfit.imagePath)) ?? false
        if imageExists {
            outfit = outfit.copyWith(\.imageSource, value: .storagePath(outfit.imagePath))
        }

        let thumbnailExists = (try? await storage.exists(at: outfit.thumbnailPath)) ?? false
        if thumbnailExists {
            outfit = outfit.copyWith(\.thumbnailSource, value: .storagePath(outfit.thumbnailPath))
        }

        return outfit
    }

    private func join(_ outfits: [Outfit], with items: [Item]) -> [Outfit] {
        let outfits = outfits.map { outfit in
            if !outfit.items.isEmpty {
                return outfit
            }

            return outfit.copyWith(\.items, value: outfit.itemIDs.compactMap { itemID in
                items.first { $0.id == itemID }
            })
        }
        logger.debug("joined outfits with items at the client side")
        return outfits
    }
}
