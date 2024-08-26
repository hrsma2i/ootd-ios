//
//  SampleOutfitDataSource.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/14.
//

import Foundation

class SampleOutfitDataSource: OutfitDataSource {
    func fetch() async throws -> [Outfit] {
        sampleOutfits
    }

    func create(_ outfits: [Outfit]) -> [Outfit] {
        outfits.map { outfit in
            if outfit.id != nil {
                return outfit
            }

            return outfit.copyWith(\.id, value: UUID().uuidString)
        }
    }

    func update(_: [Outfit]) async throws {}

    func delete(_: [Outfit]) async throws {}
}
