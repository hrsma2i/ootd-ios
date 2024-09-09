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
        init(id: String? = nil, category: String = Category.uncategorized.rawValue, sourceUrl: String? = nil) {
            self.id = id ?? UUID().uuidString
            self.category = category
            self.sourceUrl = sourceUrl
        }

        init(from item: Item) {
            self.id = item.id ?? UUID().uuidString
            self.category = item.category.rawValue
            self.sourceUrl = item.sourceUrl
        }

        @Attribute(.unique) var id: String
        var category: String
        var sourceUrl: String?
    }

    var container: ModelContainer
    var context: ModelContext

    @MainActor
    static let shared = SwiftDataItemDataSource()

    @MainActor
    private init() {
        self.container = try! ModelContainer(for: ItemDTO.self)
        self.context = container.mainContext
    }

    func fetch() async throws -> [Item] {
        logger.debug("[SwiftData] fetch all items")
        let descriptor = FetchDescriptor<ItemDTO>()
        let dtos = try context.fetch(descriptor)
        let items = try dtos.map(toItem)
        return items
    }

    func create(_ items: [Item]) async throws -> [Item] {
        var itemsWithId = [Item]()

        for item in items {
            do {
                let dto = try toDTO(item)
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

        guard let imagePath = item.imagePath,
              let thumbnailPath = item.thumbnailPath
        else {
            throw "\(header) either imagePath or thumbnailPath is nil"
        }

        let image: UIImage
        if let image_ = item.image {
            image = image_
        } else if let url = item.imageURL {
            let data = try await downloadImage(url)
            guard let image_ = UIImage(data: data) else {
                throw "\(header) it failed to convert the downloaded data to UIImage"
            }
            image = image_
        } else {
            throw "\(header) the item.image == nil or it failed to download the image from item.imageURL"
        }

        try LocalStorage.save(image: image.resized(to: Item.imageSize), to: imagePath)
        try LocalStorage.save(image: image.resized(to: Item.thumbnailSize), to: thumbnailPath)
    }

    func update(_ items: [Item]) async throws {
        // SwiftData は context に同一idのオブジェクトが複数存在する場合、 save 時点の最後のオブジェクトが採用されるので、 insert でよい。
        for item in items {
            do {
                let dto = try toDTO(item)
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
                let dto = try toDTO(item)
                logger.debug("[SwiftData] delete item id=\(dto.id)")
                context.delete(dto)

                guard let imagePath = item.imagePath,
                      let thumbnailPath = item.thumbnailPath
                else {
                    throw "[SwiftData] either imagePath or thumbnailPath is nil"
                }

                try LocalStorage.remove(at: imagePath)
                try LocalStorage.remove(at: thumbnailPath)
            } catch {
                logger.error("\(error)")
            }
        }
    }

    private func toItem(_ dto: ItemDTO) throws -> Item {
        guard let category = Category(rawValue: dto.category) else {
            throw "failed to convert ItemDTO to Item. unknown category: \(dto.category)"
        }

        return Item(
            id: dto.id,
            category: category,
            sourceUrl: dto.sourceUrl
        )
    }

    private func toDTO(_ item: Item) throws -> ItemDTO {
        guard let id = item.id else {
            logger.debug("[toDTO] item.id == nil, so create new ItemDTO")
            return ItemDTO(from: item)
        }

        let descriptor = FetchDescriptor<ItemDTO>(predicate: #Predicate { dto in
            dto.id == id
        })

        // すでに container 内に保存済みのDTOと同じ id のDTOを生成すると、 DTO.id の参照時に EXC_BREAKPOINT のエラーが発生してしまう。
        // id に @Attribute(.unique) 制約があるため起こる。
        // なので、すでに保存済みの場合は container から取得する
        if let dto = try context.fetch(descriptor).first {
            logger.debug("[toDTO] ItemDTO with id=\(id) has alraedy exists, so get it from the container")
            dto.category = item.category.rawValue
            return dto
        } else {
            logger.debug("[toDTO] create new ItemDTO with id=\(id)")
            return ItemDTO(from: item)
        }
    }

    func deleteAll() throws {
        logger.warning("[SwiftData] delete all items")
        try context.delete(model: ItemDTO.self)
    }
}
