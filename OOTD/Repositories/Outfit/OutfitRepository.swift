//
//  OutfitRepository.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/14.
//

import Foundation

protocol OutfitRepository {
    var shouldClientSideJoin: Bool { get }

    func findAll() async throws -> [Outfit]

    func save(_ outfits: [Outfit]) async throws

    func delete(_ outfits: [Outfit]) async throws
}
