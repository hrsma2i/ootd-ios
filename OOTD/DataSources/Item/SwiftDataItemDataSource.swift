//
//  SwiftDataItemDataSource.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/27.
//

import Foundation
import SwiftData
import UIKit

private let logger = getLogger(#file)

final class SwiftDataItemDataSource: ItemDataSource {
    @Model
    class ItemDTO {
        typealias OutfitDTO = SwiftDataOutfitDataSource.OutfitDTO

        init(id: String, category: String = Category.uncategorized.rawValue, sourceUrl: String? = nil, outfits: [OutfitDTO] = []) {
            self.id = id
            self.category = category
            self.sourceUrl = sourceUrl
            self.outfits = outfits
        }

        @Attribute(.unique) var id: String
        var category: String
        var sourceUrl: String?
        @Relationship(inverse: \OutfitDTO.items) var outfits: [OutfitDTO]

        func toItem() throws -> Item {
            guard let category = Category(rawValue: category) else {
                throw "[ItemDTO.toItem] failed to convert ItemDTO to Item. unknown category: \(category)"
            }

            return Item(
                id: id,
                category: category,
                sourceUrl: sourceUrl
            )
        }

        // TODO: create と update で関数わけて良さそう。 create 時に余計なオーバーヘッドあるし
        static func from(item: Item, context: ModelContext) throws -> ItemDTO {
            func toDTO(_ item: Item) -> ItemDTO {
                return ItemDTO(
                    id: item.id,
                    category: item.category.rawValue,
                    sourceUrl: item.sourceUrl
                )
            }

            // dto.id == item.id としてしまうと、以下のエラーになるので、いったん String だけの変数にしてる
            // Cannot convert value of type 'PredicateExpressions.Equal<PredicateExpressions.KeyPath<PredicateExpressions.Variable<SwiftDataItemDataSource.ItemDTO>, String>, PredicateExpressions.KeyPath<PredicateExpressions.Value<Item>, String>>' to closure result type 'any StandardPredicateExpression<Bool>'
            let id = item.id
            let descriptor = FetchDescriptor<ItemDTO>(predicate: #Predicate { dto in
                dto.id == id
            })

            // すでに container 内に保存済みのDTOと同じ id のDTOを生成すると、 DTO.id の参照時に EXC_BREAKPOINT のエラーが発生してしまう。
            // id に @Attribute(.unique) 制約があるため起こる。
            // なので、すでに保存済みの場合は container から取得する
            if let dto = try context.fetch(descriptor).first {
                logger.debug("[ItemDTO.from(Item)] ItemDTO with id=\(id) has alraedy exists, so get it from the container")
                dto.category = item.category.rawValue
                return dto
            } else {
                logger.debug("[ItemDTO.from(Item)] create new ItemDTO with id=\(id)")
                return toDTO(item)
            }
        }
    }

    var context: ModelContext

    @MainActor
    static let shared = SwiftDataItemDataSource()

    @MainActor
    private init() {
        self.context = SwiftDataManager.shared.context
    }

    func fetch() async throws -> [Item] {
        logger.debug("[SwiftData] fetch all items")
        let descriptor = FetchDescriptor<ItemDTO>()
        let dtos = try context.fetch(descriptor)
        let items = dtos.compactMap {
            do {
                return try $0.toItem()
            } catch {
                logger.error("\(error)")
                return nil
            }
        }
        return items
    }

    func create(_ items: [Item]) async throws -> [Item] {
        // TODO: Item.id が not null になったので [Item] を返す必要がなくなった
        var itemsWithId = [Item]()

        for item in items {
            do {
                let dto = try ItemDTO.from(item: item, context: context)
                context.insert(dto)
                logger.debug("[SwiftData] insert new item id=\(dto.id)")

                try await saveImage(item)

                itemsWithId.append(item)
            } catch {
                logger.error("\(error)")
            }
        }
        try context.save()
        logger.debug("[SwiftData] save")

        return itemsWithId
    }

    func saveImage(_ item: Item) async throws {
        let image = try await item.getUiImage()

        // TODO: id が not nil になったので、 Item.imagePath みたいに取りたい
        let imagePath = Item.generateImagePath(item.id, size: Item.imageSize)
        let thumbnailPath = Item.generateImagePath(item.id, size: Item.thumbnailSize)

        try LocalStorage.save(image: image.resized(to: Item.imageSize), to: imagePath)
        try LocalStorage.save(image: image.resized(to: Item.thumbnailSize), to: thumbnailPath)
    }

    func update(_ items: [Item]) async throws {
        // SwiftData は context に同一idのオブジェクトが複数存在する場合、 save 時点の最後のオブジェクトが採用されるので、 insert でよい。
        for item in items {
            do {
                let dto = try ItemDTO.from(item: item, context: context)
                context.insert(dto)
                logger.debug("[SwiftData] insert updated item id=\(dto.id)")

                // TODO: 画像を編集したときだけ更新したい
                try await saveImage(item)
            } catch {
                logger.error("\(error)")
            }
        }
        try context.save()
        logger.debug("[SwiftData] save")
    }

    func delete(_ items: [Item]) async throws {
        for item in items {
            do {
                let dto = try ItemDTO.from(item: item, context: context)
                // Item.imageSource が .localPath のときだけ削除するのはダメ
                // create したばかりのアイテムをすぐ削除しようとすると imageSource = .uiImage | .url となり、
                // LocalStorage に保存した画像が削除されなくなる
                let imagePath = Item.generateImagePath(item.id, size: Item.imageSize)
                let thumbnailPath = Item.generateImagePath(item.id, size: Item.thumbnailSize)
                try LocalStorage.remove(at: imagePath)
                try LocalStorage.remove(at: thumbnailPath)

                context.delete(dto)
                logger.debug("[SwiftData] delete item id=\(item.id)")
            } catch {
                logger.error("\(error)")
            }
        }
    }

    func deleteAll() throws {
        logger.warning("[SwiftData] delete all items")
        try context.delete(model: ItemDTO.self)
    }
}
