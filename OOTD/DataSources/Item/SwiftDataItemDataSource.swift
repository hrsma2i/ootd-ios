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

        init(id: String? = nil, category: String = Category.uncategorized.rawValue, sourceUrl: String? = nil, outfits: [OutfitDTO] = []) {
            self.id = id ?? UUID().uuidString
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

        static func from(item: Item, context: ModelContext) throws -> ItemDTO {
            func toDTO(_ item: Item) -> ItemDTO {
                return ItemDTO(
                    id: item.id ?? UUID().uuidString,
                    category: item.category.rawValue,
                    sourceUrl: item.sourceUrl
                )
            }

            guard let id = item.id else {
                logger.debug("[ItemDTO.from(Item)] item.id == nil, so create new ItemDTO")
                return toDTO(item)
            }

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
        var itemsWithId = [Item]()

        for item in items {
            do {
                let dto = try ItemDTO.from(item: item, context: context)
                context.insert(dto)
                logger.debug("[SwiftData] insert new item id=\(dto.id)")

                let itemWithId = item.copyWith(\.id, value: dto.id)
                try await saveImage(itemWithId)

                itemsWithId.append(itemWithId)
            } catch {
                logger.error("\(error)")
            }
        }
        try context.save()
        logger.debug("[SwiftData] save")

        return itemsWithId
    }

    func saveImage(_ item: Item) async throws {
        let header = "failed to save an item image to the local storage because"

        let image = try await item.getUiImage()

        guard let id = item.id else {
            throw "\(header) Item.id is nil"
        }

        let imagePath = Item.generateImagePath(id, size: Item.imageSize)
        let thumbnailPath = Item.generateImagePath(id, size: Item.thumbnailSize)

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
                logger.debug("[SwiftData] delete item id=\(dto.id)")
                context.delete(dto)

                // Item.imageSource が .localPath のときだけ削除するのはダメ
                // create したばかりのアイテムをすぐ削除しようとすると imageSource = .uiImage | .url となり、
                // LocalStorage に保存した画像が削除されなくなる
                let imagePath = Item.generateImagePath(dto.id, size: Item.imageSize)
                let thumbnailPath = Item.generateImagePath(dto.id, size: Item.thumbnailSize)

                try LocalStorage.remove(at: imagePath)
                try LocalStorage.remove(at: thumbnailPath)
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
