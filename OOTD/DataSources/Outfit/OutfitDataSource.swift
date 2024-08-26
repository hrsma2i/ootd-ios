//
//  OutfitDataSource.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/14.
//

import Foundation

protocol OutfitDataSource {
    func fetch() async throws -> [Outfit]

    func create(_ outfits: [Outfit]) async throws -> [Outfit]

    func update(_ outfits: [Outfit]) async throws

    func delete(_ outfits: [Outfit]) async throws
}
