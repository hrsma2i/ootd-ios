
//
//  SwiftDataOutfitRepository.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/27.
//

import Foundation
import SwiftData
import UIKit

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

    @MainActor
    func findAll() async throws -> [Outfit] {
        logger.debug("fetch all outfits")
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
                logger.debug("\(message) id=\(dto.id)")
            } catch {
                logger.critical("\(error)")
            }
        }
        try context.save()
        logger.debug("save context")
    }

    func delete(_ outfits: [Outfit]) async throws {
        for outfit in outfits {
            do {
                guard let dto = try fetchSingle(outfit: outfit) else {
                    throw "[SwiftData] no item id=\(outfit.id)"
                }

                context.delete(dto)
                logger.debug("delete outfit id=\(outfit.id)")
            } catch {
                logger.critical("\(error)")
            }
        }

        try context.save()
        logger.debug("save context")
    }

    func deleteAll() throws {
        logger.warning("delete all outfits")
        try context.delete(model: OutfitDTO.self)
    }
}
