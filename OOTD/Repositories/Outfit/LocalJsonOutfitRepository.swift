//
//  LocalJsonOutfitRepository.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/15.
//

import Foundation

extension Outfit: Codable {
    enum CodingKeys: String, CodingKey {
        case id,
             itemIds = "item_ids",
             tags,
             createdAt,
             updatedAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(itemIDs, forKey: .itemIds)
        try container.encode(tags, forKey: .tags)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        itemIDs = try container.decode([String].self, forKey: .itemIds)
        items = []
        tags = try container.decode([String].self, forKey: .tags)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

struct LocalJsonOutfitRepository: OutfitRepository {
    var shouldClientSideJoin: Bool { true }

    static let shared: LocalJsonOutfitRepository = .init()

    private init() {}

    private let storage = LocalStorage.documentsBuckup

    let className = String(describing: Self.self)

    func header(funcName: String = #function) -> String {
        "[\(className).\(#function)]"
    }

    private let jsonName = "outfits.json"

    func findAll() async throws -> [Outfit] {
        let decoder = JSONDecoder()
        guard let data = try? await storage.load(from: jsonName) else {
            return []
        }
        let outfits = try decoder.decode([Outfit].self, from: data)
        logger.debug("fetched \(outfits.count) outfits")
        return outfits
    }

    func save(_ outfits: [Outfit]) async throws {
        var allOutfits = try await findAll()

        for newOutfit in outfits {
            if let index = allOutfits.firstIndex(where: { $0.id == newOutfit.id }) {
                allOutfits[index] = newOutfit
            }
            allOutfits.append(newOutfit)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // オプション: JSONを読みやすくフォーマット

        do {
            let jsonData = try encoder.encode(allOutfits)
            try await storage.save(data: jsonData, to: jsonName)
            logger.debug("saved \(outfits.count) outfits")
        } catch {
            logger.debug("failed to save outfits: \(error)")
        }
    }

    func delete(_ outfits: [Outfit]) async throws {
        throw "\(header()) not implemented"
    }
}
