
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
        init(id: String, items: [ItemDTO]) {
            self.id = id
            self.items = items
        }

        @Attribute(.unique) var id: String
        var items: [ItemDTO]

        // create 時のみ使う。 update, delete 時は .fetchSingle() を使う
        // なぜなら、すでに container 内に保存済みのDTOと同じ id のDTOを生成すると、 DTO.id の参照時に EXC_BREAKPOINT のエラーが発生してしまうから。
        // この原因は id に @Attribute(.unique) 制約があるから。なので、すでに保存済み（update, delete）の場合は container から取得する。
        init(outfit: Outfit) {
            id = outfit.id

            items = []
            do {
                items = try SwiftDataItemDataSource.shared.fetch(items: outfit.items)
            } catch {
                logger.error("\(error)")
            }
        }

        func toOutfit() throws -> Outfit {
            let imagePath = Outfit.generateImagePath(id, size: Outfit.imageSize)
            let thumbnailPath = Outfit.generateImagePath(id, size: Outfit.thumbnailSize)

            let imageSource: ImageSource?
            let thumbnailSource: ImageSource?
            do {
                // check there are images in the storage
                let _ = try LocalStorage.loadImage(from: imagePath)
                let _ = try LocalStorage.loadImage(from: thumbnailPath)
                imageSource = .localPath(imagePath)
                thumbnailSource = .localPath(thumbnailPath)
            } catch {
                imageSource = nil
                thumbnailSource = nil
            }

            return Outfit(
                id: id,
                // そのまま toItem による [Item] を items に渡したい
                itemIds: items.compactMapWithErrorLog(logger) { itemDto in
                    try itemDto.toItem().id
                },
                imageSource: imageSource,
                thumbnailSource: thumbnailSource
            )
        }
    }

    var context: ModelContext

    @MainActor
    static let shared = SwiftDataOutfitDataSource()

    @MainActor
    private init() {
        context = SwiftDataManager.shared.context
    }

    func fetchSingle(outfit: Outfit) throws -> OutfitDTO {
        // dto.id == outfit.id としてしまうと、以下のエラーになるので、いったん String だけの変数にしてる
        // Cannot convert value of type 'PredicateExpressions.Equal<PredicateExpressions.KeyPath<PredicateExpressions.Variable<SwiftDataOutfitDataSource.OutfitDTO>, String>, PredicateExpressions.KeyPath<PredicateExpressions.Value<Outfit>, String>>' to closure result type 'any StandardPredicateExpression<Bool>'
        let id = outfit.id
        let descriptor = FetchDescriptor<OutfitDTO>(predicate: #Predicate { dto in
            dto.id == id
        })

        guard let dto = try context.fetch(descriptor).first else {
            throw "[OutfitDTO.fetch(outfit)] there is no OutfitDTO with id=\(id) in container"
        }
        logger.debug("[OutfitDTO.from(Outfit)] OutfitDTO with id=\(id) has alraedy exists, so get it from the container")
        return dto
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

    func create(_ outfits: [Outfit]) async throws {
        for outfit in outfits {
            do {
                // Item と異なり、 imageSource = nil はよくあることなので、 Outfit 自体の保存は中断されないようにする
                if outfit.imageSource != nil {
                    try await saveImage(outfit)
                }

                let dto = OutfitDTO(outfit: outfit)
                context.insert(dto)
                logger.debug("[SwiftData] insert new outfit id=\(dto.id)")
            } catch {
                logger.error("\(error)")
            }
        }
        try context.save()
        logger.debug("[SwiftData] save")
    }

    func saveImage(_ outfit: Outfit) async throws {
        let image = try await outfit.getUiImage()

        try LocalStorage.save(image: image.resized(to: Outfit.imageSize), to: outfit.imagePath)
        try LocalStorage.save(image: image.resized(to: Outfit.thumbnailSize), to: outfit.thumbnailPath)
    }

    func update(_ outfits: [Outfit]) async throws {
        // SwiftData は context に同一idのオブジェクトが複数存在する場合、 save 時点の最後のオブジェクトが採用されるので、 insert でよい。
        for outfit in outfits {
            do {
                let dto = try fetchSingle(outfit: outfit)

                dto.items = try SwiftDataItemDataSource.shared.fetch(items: outfit.items)

                context.insert(dto)
                logger.debug("[SwiftData] insert updated outfit id=\(dto.id)")

                // TODO: 画像を編集したときだけ更新したい
                if outfit.imageSource != nil {
                    try await saveImage(outfit)
                }
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
                let dto = try fetchSingle(outfit: outfit)

                context.delete(dto)
                logger.debug("[SwiftData] delete outfit id=\(outfit.id)")

                // .imageSource == .localPath のときだけ削除するのはダメ
                // create したばかりのものをすぐ削除しようとすると imageSource = .uiImage | .url となり、
                // LocalStorage に保存した画像が削除されなくなる
                // Item と異なり、 imageSource = nil の場合が普通にあり、その場合は削除不要。
                if outfit.imageSource != nil {
                    try LocalStorage.remove(at: outfit.imagePath)
                    try LocalStorage.remove(at: outfit.thumbnailPath)
                }
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
