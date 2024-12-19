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

    @MainActor
    func callAsFunction() async throws -> [Outfit] {
        var outfits = try await repository.findAll()
        // TODO: 順序保証されてれば isParallel: true にしたほうが初回読み込みが速そう
        outfits = await outfits.asyncMap(isParallel: false) {
            await setImageSourceIfExists($0)
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
}
