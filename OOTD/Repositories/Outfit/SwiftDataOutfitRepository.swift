
//
//  SwiftDataOutfitRepository.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/27.
//

import Foundation
import SwiftData
import UIKit

private let logger = getLogger(#file)

typealias OutfitDTO = SchemaV7.OutfitDTO

final class SwiftDataOutfitRepository: OutfitRepository {
    var context: ModelContext

    @MainActor
    static let shared = SwiftDataOutfitRepository()

    @MainActor
    private init() {
        context = SwiftDataManager.shared.context
    }

    func fetchSingle(outfit: Outfit) throws -> OutfitDTO? {
        // dto.id == outfit.id としてしまうと、以下のエラーになるので、いったん String だけの変数にしてる
        // Cannot convert value of type 'PredicateExpressions.Equal<PredicateExpressions.KeyPath<PredicateExpressions.Variable<SwiftDataOutfitRepository.OutfitDTO>, String>, PredicateExpressions.KeyPath<PredicateExpressions.Value<Outfit>, String>>' to closure result type 'any StandardPredicateExpression<Bool>'
        let id = outfit.id
        let descriptor = FetchDescriptor<OutfitDTO>(predicate: #Predicate { dto in
            dto.id == id
        })

        let dto = try context.fetch(descriptor).first
        return dto
    }

    func findAll() async throws -> [Outfit] {
        logger.debug("[SwiftData] fetch all outfits")
        let descriptor = FetchDescriptor<OutfitDTO>()
        let dtos = try context.fetch(descriptor)
        let outfits = await dtos.asyncCompactMap(isParallel: false) {
            do {
                return try await $0.toOutfit()
            } catch {
                logger.warning("\(error)")
                return nil
            }
        }
        return outfits
    }

    func save(_ outfits: [Outfit]) async throws {
        for outfit in outfits {
            do {
                // TODO: 画像を編集したときだけ更新したい
                // Item と異なり、 imageSource = nil はよくあることなので、 Outfit 自体の保存は中断されないようにする
                if outfit.imageSource != nil {
                    try await saveImage(outfit)
                }

                let dto: OutfitDTO
                let message: String
                if let existing = try fetchSingle(outfit: outfit) {
                    dto = existing
                    try dto.update(from: outfit)
                    message = "update an existing outfit"
                } else {
                    dto = OutfitDTO(outfit: outfit)
                    message = "create a new outfit"
                }

                // SwiftData は context に同一idのオブジェクトが複数存在する場合、 save 時点の最後のオブジェクトが採用されるので、 update の場合も insert でよい。
                context.insert(dto)
                logger.debug("[SwiftData] \(message) id=\(dto.id)")
            } catch {
                logger.error("\(error)")
            }
        }
        try context.save()
        logger.debug("[SwiftData] save context")
    }

    func saveImage(_ outfit: Outfit) async throws {
        guard let image = try await outfit.imageSource?.getUiImage() else {
            // 画像がない場合は特に何もしない
            return
        }

        try await LocalStorage.applicationSupport.saveImage(image: image.resized(to: Outfit.imageSize), to: outfit.imagePath)
        try await LocalStorage.applicationSupport.saveImage(image: image.resized(to: Outfit.thumbnailSize), to: outfit.thumbnailPath)
    }

    func delete(_ outfits: [Outfit]) async throws {
        for outfit in outfits {
            do {
                guard let dto = try fetchSingle(outfit: outfit) else {
                    throw "[SwiftData] no item id=\(outfit.id)"
                }

                context.delete(dto)
                logger.debug("[SwiftData] delete outfit id=\(outfit.id)")

                // .imageSource == .localPath のときだけ削除するのはダメ
                // create したばかりのものをすぐ削除しようとすると imageSource = .uiImage | .url となり、
                // LocalStorage に保存した画像が削除されなくなる
                // Item と異なり、 imageSource = nil の場合が普通にあり、その場合は削除不要。
                if outfit.imageSource != nil {
                    try await LocalStorage.applicationSupport.remove(at: outfit.imagePath)
                    try await LocalStorage.applicationSupport.remove(at: outfit.thumbnailPath)
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
