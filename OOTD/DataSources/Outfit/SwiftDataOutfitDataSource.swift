
//
//  SwiftDataOutfitDataSource.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/27.
//

import Foundation
import SwiftData
import UIKit

private let logger = getLogger(#file)

final class SwiftDataOutfitDataSource: OutfitDataSource {
    @Model
    class OutfitDTO {
        typealias ItemDTO = SwiftDataItemDataSource.ItemDTO

        init(id: String? = nil, items: [ItemDTO]) {
            self.id = id ?? UUID().uuidString
            self.items = items
        }

        @Attribute(.unique) var id: String
        var items: [ItemDTO]

        func toOutfit() throws -> Outfit {
            return Outfit(
                id: id,
                items: items.compactMapWithErrorLog(logger) {
                    try $0.toItem()
                }
            )
        }

        static func from(outfit: Outfit, context: ModelContext) throws -> OutfitDTO {
            func itemsToItemDTOs(_ items: [Item]) -> [ItemDTO] {
                return items.compactMapWithErrorLog(logger) {
                    try ItemDTO.from(item: $0, context: context)
                }
            }

            func toDTO(_ outfit: Outfit) -> OutfitDTO {
                // to avoid “illegal attempt to establish a relationship between objects in different contexts"
                // https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-many-to-many-relationships
                let dto = OutfitDTO(
                    id: outfit.id,
                    items: []
                )
                dto.items.append(contentsOf: itemsToItemDTOs(outfit.items))
                return dto
            }

            guard let id = outfit.id else {
                logger.debug("[OutfitDTO.from(Outfit)] outfit.id == nil, so create new OutfitDTO")
                return toDTO(outfit)
            }

            let descriptor = FetchDescriptor<OutfitDTO>(predicate: #Predicate { dto in
                dto.id == id
            })

            // すでに container 内に保存済みのDTOと同じ id のDTOを生成すると、 DTO.id の参照時に EXC_BREAKPOINT のエラーが発生してしまう。
            // id に @Attribute(.unique) 制約があるため起こる。
            // なので、すでに保存済みの場合は container から取得する
            if let dto = try context.fetch(descriptor).first {
                logger.debug("[OutfitDTO.from(Outfit)] OutfitDTO with id=\(id) has alraedy exists, so get it from the container")
                dto.items = itemsToItemDTOs(outfit.items)
                return dto
            } else {
                logger.debug("[OutfitDTO.from(Outfit)] create new OutfitDTO with id=\(id)")
                return toDTO(outfit)
            }
        }
    }

    var context: ModelContext

    @MainActor
    static let shared = SwiftDataOutfitDataSource()

    @MainActor
    private init() {
        self.context = SwiftDataManager.shared.context
    }

    func fetch() async throws -> [Outfit] {
        logger.debug("[SwiftData] fetch all outfits")
        let descriptor = FetchDescriptor<OutfitDTO>()
        let dtos = try context.fetch(descriptor)
        let outfits = dtos.compactMapWithErrorLog(logger) {
            try $0.toOutfit()
        }
        return outfits
    }

    func create(_ outfits: [Outfit]) async throws -> [Outfit] {
        var outfitsWithId = [Outfit]()

        for outfit in outfits {
            do {
                let dto = try OutfitDTO.from(outfit: outfit, context: context)
                context.insert(dto)
                logger.debug("[SwiftData] insert new outfit id=\(dto.id)")

                let outfitWithId = outfit.copyWith(\.id, value: dto.id)
                // Item と異なり、画像が無くても保存できるようにする
                if outfit.image != nil, outfit.imageURL != nil {
                    try await saveImage(outfitWithId)
                }

                outfitsWithId.append(outfitWithId)
            } catch {
                logger.error("\(error)")
            }
        }
        try context.save()
        logger.debug("[SwiftData] save")

        return outfitsWithId
    }

    func saveImage(_ outfit: Outfit) async throws {
        let header = "failed to save an outfit image to the local storage because"

        guard let imagePath = outfit.imagePath,
              let thumbnailPath = outfit.thumbnailPath
        else {
            throw "\(header) either imagePath or thumbnailPath is nil"
        }

        let image: UIImage
        if let image_ = outfit.image {
            image = image_
        } else if let url = outfit.imageURL {
            let data = try await downloadImage(url)
            guard let image_ = UIImage(data: data) else {
                throw "\(header) it failed to convert the downloaded data to UIImage"
            }
            image = image_
        } else {
            throw "\(header) the outfit.image == nil or it failed to download the image from outfit.imageURL"
        }

        try LocalStorage.save(image: image.resized(to: Outfit.imageSize), to: imagePath)
        try LocalStorage.save(image: image.resized(to: Outfit.thumbnailSize), to: thumbnailPath)
    }

    func update(_ outfits: [Outfit]) async throws {
        // SwiftData は context に同一idのオブジェクトが複数存在する場合、 save 時点の最後のオブジェクトが採用されるので、 insert でよい。
        for outfit in outfits {
            do {
                let dto = try OutfitDTO.from(outfit: outfit, context: context)
                context.insert(dto)
                logger.debug("[SwiftData] insert updated outfit id=\(dto.id)")

                // TODO: 画像を編集したときだけ更新したい
                try await saveImage(outfit)
            } catch {
                logger.error("\(error)")
            }
        }
        try context.save()
        logger.debug("[SwiftData] save")
    }

    func delete(_ outfits: [Outfit]) async throws {
        for outfit in outfits {
            do {
                let dto = try OutfitDTO.from(outfit: outfit, context: context)
                logger.debug("[SwiftData] delete outfit id=\(dto.id)")
                context.delete(dto)

                guard let imagePath = outfit.imagePath,
                      let thumbnailPath = outfit.thumbnailPath
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

    func deleteAll() throws {
        logger.warning("[SwiftData] delete all outfits")
        try context.delete(model: OutfitDTO.self)
    }
}
