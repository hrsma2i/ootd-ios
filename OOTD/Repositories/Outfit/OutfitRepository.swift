//
//  OutfitRepository.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/14.
//

import Foundation

protocol OutfitRepository {
    func findAll() async throws -> [Outfit]

    func create(_ outfits: [Outfit]) async throws

    func update(_ outfits: [Outfit]) async throws

    func delete(_ outfits: [Outfit]) async throws
}
