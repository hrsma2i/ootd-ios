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
        imageSource = .applicatinoSupport(Item.generateImagePath(id, size: Item.imageSize))
        thumbnailSource = .applicatinoSupport(Item.generateImagePath(id, size: Item.thumbnailSize))
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

    private init() {}

    let className = String(describing: Self.self)

    func header(funcName: String = #function) -> String {
        "[\(className).\(#function)]"
    }

    func backup(_ path: String) -> String {
        "backup/\(path)"
    }

    func fetch() async throws -> [Item] {
        let decoder = JSONDecoder()
        let data = try LocalStorage.documents.load(from: backup("items.json"))
        var items = try decoder.decode([Item].self, from: data)
        items = items.map { item in
            item.copyWith(\.imageSource, value: .documents(backup(item.imagePath)))
        }
        return items
    }

    func create(_ items: [Item]) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // オプション: JSONを読みやすくフォーマット
        let jsonData = try encoder.encode(items)

        for item in items {
            let image = try await item.imageSource.getUiImage()
            try LocalStorage.documents.save(image: image, to: backup(item.imagePath))
        }

        try LocalStorage.documents.save(data: jsonData, to: backup("items.json"))
    }

    func update(_ items: [Item]) async throws {
        throw "\(header()) not implemented"
    }

    func delete(_ items: [Item]) async throws {
        throw "\(header()) not implemented"
    }
}
