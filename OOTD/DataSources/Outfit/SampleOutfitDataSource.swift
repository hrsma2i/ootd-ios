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

    func create(_: [Outfit]) {}

    func update(_: [Outfit]) async throws {}

    func delete(_: [Outfit]) async throws {}
}
