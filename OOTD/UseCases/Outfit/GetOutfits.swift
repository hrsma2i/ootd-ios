//
//  GetOutfits.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/27.
//

import Foundation

struct GetOutfits {
    let repository: OutfitRepository

    func callAsFunction() async throws -> [Outfit] {
        let outfits = try await repository.findAll()
        return outfits
    }
}
