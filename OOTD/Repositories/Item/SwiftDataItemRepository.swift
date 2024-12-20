//
//  SwiftDataItemRepository.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/27.
//

import Foundation
import SwiftData
import UIKit

typealias ItemDTO = SchemaV7.ItemDTO

final class SwiftDataItemRepository: ItemRepository {
    var context: ModelContext

    var className: String {
        String(describing: Self.self)
    }

    static let shared = SwiftDataItemRepository()

    private init() {
        context = SwiftDataManager.shared.context
    }

    @MainActor
    func findAll() async throws -> [Item] {
        logger.debug("fetch all items")
        let descriptor = FetchDescriptor<ItemDTO>()
        let dtos = try context.fetch(descriptor)
        let items = dtos.compactMap {
            do {
                return try $0.toItem()
            } catch {
                logger.critical("\(error)")
                return nil
            }
        }
        return items
    }

    func save(_ items: [Item]) async throws -> [(item: Item, error: Error?)] {
        let results: [(item: Item, error: Error?)] = await items.asyncMap(isParallel: false) { item in
            do {
                let dto: ItemDTO
                let message: String
                if let existing = try self.fetchSingle(item: item) {
                    dto = existing
                    dto.update(from: item)
                    message = "update an existing item"
                } else {
                    dto = ItemDTO(item: item)
                    message = "create a new item"
                }

                // SwiftData は context に同一idのオブジェクトが複数存在する場合、 save 時点の最後のオブジェクトが採用されるので、 update の場合も insert でよい。
                self.context.insert(dto)
                logger.debug("\(message) id=\(dto.id)")
                return (item: item, error: nil)
            } catch {
                return (item: item, error: error)
            }
        }
        try context.save()
        logger.debug("save context")
        return results
    }

    func fetch(items: [Item]) throws -> [ItemDTO] {
        // dto.id == item.id としてしまうと、以下のエラーになるので、いったん String だけの変数にしてる
        // Cannot convert value of type 'PredicateExpressions.SequenceContainsWhere<PredicateExpressions.Value<[Item]>, PredicateExpressions.Equal<PredicateExpressions.KeyPath<PredicateExpressions.Variable<Item>, String>, PredicateExpressions.KeyPath<PredicateExpressions.Variable<ItemDTO>, String>>>' (aka 'PredicateExpressions.SequenceContainsWhere<PredicateExpressions.Value<Array<Item>>, PredicateExpressions.Equal<PredicateExpressions.KeyPath<PredicateExpressions.Variable<Item>, String>, PredicateExpressions.KeyPath<PredicateExpressions.Variable<SchemaV4.ItemDTO>, String>>>') to closure result type 'any StandardPredicateExpression<Bool>'
        let ids = items.map(\.id)
        let descriptor = FetchDescriptor<ItemDTO>(predicate: #Predicate { dto in
            ids.contains(dto.id)
        })

        let dtos = try context.fetch(descriptor)

        logger.debug("ItemDTOs have already exist, so get them from the container")
        return dtos
    }

    func fetchSingle(item: Item) throws -> ItemDTO? {
        // dto.id == item.id としてしまうと、以下のエラーになるので、いったん String だけの変数にしてる
        // Cannot convert value of type 'PredicateExpressions.Equal<PredicateExpressions.KeyPath<PredicateExpressions.Variable<SwiftDataItemRepository.ItemDTO>, String>, PredicateExpressions.KeyPath<PredicateExpressions.Value<Item>, String>>' to closure result type 'any StandardPredicateExpression<Bool>'
        let id = item.id
        let descriptor = FetchDescriptor<ItemDTO>(predicate: #Predicate { dto in
            dto.id == id
        })

        let dto = try context.fetch(descriptor).first
        return dto
    }

    func delete(_ items: [Item]) async throws {
        for item in items {
            do {
                guard let dto = try fetchSingle(item: item) else {
                    throw "no item id=\(item.id)"
                }
                context.delete(dto)
                logger.debug("delete item id=\(item.id)")
            } catch {
                logger.critical("\(error)")
            }
        }
        try context.save()
        logger.debug("save context")
    }

    func deleteAll() throws {
        logger.warning("delete all items")
        try context.delete(model: ItemDTO.self)
    }
}
