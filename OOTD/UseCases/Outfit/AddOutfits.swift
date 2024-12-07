//
//  AddOutfits.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/27.
//

import Foundation

struct AddOutfits {
    let repository: OutfitRepository

    func callAsFunction(_ outfits: [Outfit]) async throws {
        try await repository.save(outfits)
    }
}
