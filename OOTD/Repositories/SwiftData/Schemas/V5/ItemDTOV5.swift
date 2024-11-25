//
//  ItemDTO.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/18.
//

import Foundation
import SwiftData

extension SchemaV5 {
    @Model
    class ItemDTO {
        typealias OutfitDTO = SchemaV5.OutfitDTO

        @Attribute(.unique) var id: String
        var name: String = ""
        var category: String
        var tags: [String] = []
        var purchasedPrice: Int?
        var purchasedOn: Date?
        var createdAt: Date = Date()
        var updatedAt: Date = Date()
        var sourceUrl: String?
        // original* は web からインポートした際の無加工の情報
        var originalCategoryPath: [String]?
        var originalColor: String?
        var originalBrand: String?
        var originalSize: String?
        var originalDescription: String?

        @Relationship(inverse: \OutfitDTO.items) var outfits: [OutfitDTO]

        // create 時のみ使う。 update, delete 時は .fetchSingle() を使う。
        // なぜなら、すでに container 内に保存済みのDTOと同じ id のDTOを生成すると、 DTO.id の参照時に EXC_BREAKPOINT のエラーが発生してしまうから。
        // この原因は id に @Attribute(.unique) 制約があるから。なので、すでに保存済み（update, delete）の場合は container から取得する。
        init(item: Item) {
            id = item.id
            name = item.name
            category = item.category.rawValue
            tags = item.tags
            purchasedPrice = item.purchasedPrice
            purchasedOn = item.purchasedOn
            createdAt = item.createdAt!
            updatedAt = item.updatedAt!
            sourceUrl = item.sourceUrl
            originalCategoryPath = item.originalCategoryPath
            originalColor = item.originalColor
            originalBrand = item.originalBrand
            originalSize = item.originalSize
            originalDescription = item.originalDescription
            outfits = []
        }

        func update(from item: Item) {
            name = item.name
            category = item.category.rawValue
            tags = item.tags
            purchasedPrice = item.purchasedPrice
            purchasedOn = item.purchasedOn
            updatedAt = item.updatedAt!
            // createdAt は更新する必要なし
            sourceUrl = item.sourceUrl
            originalCategoryPath = item.originalCategoryPath
            originalColor = item.originalColor
            originalBrand = item.originalBrand
            originalSize = item.originalSize
            originalDescription = item.originalDescription
        }

        func toItem() throws -> Item {
            guard let category = Category(rawValue: category) else {
                throw "[ItemDTO.toItem] failed to convert ItemDTO to Item. unknown category: \(category)"
            }

            return Item(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                option: .init(
                    name: name,
                    category: category,
                    tags: tags,
                    purchasedPrice: purchasedPrice,
                    purchasedOn: purchasedOn,
                    sourceUrl: sourceUrl,
                    originalCategoryPath: originalCategoryPath,
                    originalColor: originalColor,
                    originalBrand: originalBrand,
                    originalSize: originalSize,
                    originalDescription: originalDescription
                )
            )
        }
    }
}
