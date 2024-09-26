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

typealias ItemDTO = SchemaV2.ItemDTO

final class SwiftDataItemDataSource: ItemDataSource {
    var context: ModelContext

    static let shared = SwiftDataItemDataSource()

    private init() {
        context = SwiftDataManager.shared.context
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

    func fetchSingle(item: Item) throws -> ItemDTO {
        // dto.id == item.id としてしまうと、以下のエラーになるので、いったん String だけの変数にしてる
        // Cannot convert value of type 'PredicateExpressions.Equal<PredicateExpressions.KeyPath<PredicateExpressions.Variable<SwiftDataItemDataSource.ItemDTO>, String>, PredicateExpressions.KeyPath<PredicateExpressions.Value<Item>, String>>' to closure result type 'any StandardPredicateExpression<Bool>'
        let id = item.id
        let descriptor = FetchDescriptor<ItemDTO>(predicate: #Predicate { dto in
            dto.id == id
        })

        guard let dto = try context.fetch(descriptor).first else {
            throw "[ItemDTO.fetch(item)] there is no ItemDTO with id=\(id) in container"
        }
        logger.debug("[ItemDTO.from(Item)] ItemDTO with id=\(id) has alraedy exists, so get it from the container")
        return dto
    }

    func create(_ items: [Item]) async throws {
        for item in items {
            do {
                try await saveImage(item)

                let dto = ItemDTO(item: item)
                context.insert(dto)
                logger.debug("[SwiftData] insert new item id=\(dto.id)")

            } catch {
                logger.error("\(error)")
            }
        }
        try context.save()
        logger.debug("[SwiftData] save")
    }

    func saveImage(_ item: Item) async throws {
        let image = try await item.getUiImage()

        try LocalStorage.save(image: image.resized(to: Item.imageSize), to: item.imagePath)
        try LocalStorage.save(image: image.resized(to: Item.thumbnailSize), to: item.thumbnailPath)
    }

    func update(_ items: [Item]) async throws {
        // SwiftData は context に同一idのオブジェクトが複数存在する場合、 save 時点の最後のオブジェクトが採用されるので、 insert でよい。
        for item in items {
            do {
                let dto = try fetchSingle(item: item)

                dto.name = item.name
                dto.category = item.category.rawValue
                dto.sourceUrl = item.sourceUrl

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
                let dto = try fetchSingle(item: item)
                // Item.imageSource == .localPath のときだけ削除するのはダメ
                // create したばかりのアイテムをすぐ削除しようとすると imageSource = .uiImage | .url となり、
                // LocalStorage に保存した画像が削除されなくなる
                try LocalStorage.remove(at: item.imagePath)
                try LocalStorage.remove(at: item.thumbnailPath)

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
