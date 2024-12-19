//
//  LocalJsonItemRepository.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/13.
//

import Foundation

extension Item: Codable {
    enum CodingKeys: String, CodingKey {
        case id,
             name,
             category,
             purchasedPrice,
             purchasedOn,
             createdAt,
             updatedAt,
             sourceUrl,
             originalCategoryPath,
             originalColor,
             originalBrand,
             originalSize,
             originalDescription
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(purchasedPrice, forKey: .purchasedPrice)
        try container.encode(purchasedOn, forKey: .purchasedOn)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(sourceUrl, forKey: .sourceUrl)
        try container.encode(originalCategoryPath, forKey: .originalCategoryPath)
        try container.encode(originalColor, forKey: .originalColor)
        try container.encode(originalBrand, forKey: .originalBrand)
        try container.encode(originalSize, forKey: .originalSize)
        try container.encode(originalDescription, forKey: .originalDescription)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        imageSource = .storagePath(Item.generateImagePath(id, size: Item.imageSize))
        thumbnailSource = .storagePath(Item.generateImagePath(id, size: Item.thumbnailSize))
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(Category.self, forKey: .category)
        purchasedPrice = try container.decodeIfPresent(Int.self, forKey: .purchasedPrice)
        purchasedOn = try container.decodeIfPresent(Date.self, forKey: .purchasedOn)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        sourceUrl = try container.decodeIfPresent(String.self, forKey: .sourceUrl)
        originalCategoryPath = try container.decodeIfPresent([String].self, forKey: .originalCategoryPath)
        originalColor = try container.decodeIfPresent(String.self, forKey: .originalColor)
        originalBrand = try container.decodeIfPresent(String.self, forKey: .originalBrand)
        originalSize = try container.decodeIfPresent(String.self, forKey: .originalSize)
        originalDescription = try container.decodeIfPresent(String.self, forKey: .originalDescription)
    }
}

struct LocalJsonItemRepository: ItemRepository {
    static let shared: LocalJsonItemRepository = .init()

    private let storage = LocalStorage.documentsBuckup

    private init() {}

    let className = String(describing: Self.self)

    func header(funcName: String = #function) -> String {
        "[\(className).\(#function)]"
    }

    private let jsonName = "items.json"

    func findAll() async throws -> [Item] {
        let decoder = JSONDecoder()
        guard let data = try? await storage.load(from: jsonName) else {
            return []
        }
        let items = try decoder.decode([Item].self, from: data)
        logger.debug("fetched \(items.count) items")
        return items
    }

    func save(_ items: [Item]) async throws -> [(item: Item, error: Error?)] {
        var allItems = try await findAll()

        for newItem in items {
            if let index = allItems.firstIndex(where: { $0.id == newItem.id }) {
                allItems[index] = newItem
            }
            allItems.append(newItem)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // オプション: JSONを読みやすくフォーマット

        do {
            let jsonData = try encoder.encode(allItems)
            try await storage.save(data: jsonData, to: jsonName)
            logger.debug("saved \(items.count) items")
            return items.map { ($0, nil) }
        } catch {
            logger.debug("failed to save items: \(error)")
            return items.map { ($0, error) }
        }
    }

    func delete(_ items: [Item]) async throws {
        throw "\(header()) not implemented"
    }
}
