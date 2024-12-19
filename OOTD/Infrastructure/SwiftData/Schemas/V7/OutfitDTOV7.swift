//
//  OutfitDTOV7.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/21.
//

import Foundation
import SwiftData

extension SchemaV7 {
    @Model
    class OutfitDTO {
        typealias ItemDTO = SchemaV7.ItemDTO

        @Attribute(.unique) var id: String
        var items: [ItemDTO]
        var tags: [String] = []
        var createdAt: Date = Date()
        var updatedAt: Date = Date()

        // create 時のみ使う。 update, delete 時は .fetchSingle() を使う
        // なぜなら、すでに container 内に保存済みのDTOと同じ id のDTOを生成すると、 DTO.id の参照時に EXC_BREAKPOINT のエラーが発生してしまうから。
        // この原因は id に @Attribute(.unique) 制約があるから。なので、すでに保存済み（update, delete）の場合は container から取得する。
        init(outfit: Outfit) {
            id = outfit.id

            items = []
            do {
                items = try SwiftDataItemRepository.shared.fetch(items: outfit.items)
            } catch {
                logger.critical("\(error)")
            }

            tags = outfit.tags
            createdAt = outfit.createdAt!
            updatedAt = outfit.updatedAt!
        }

        func update(from outfit: Outfit) throws {
            items = try SwiftDataItemRepository.shared.fetch(items: outfit.items)
            tags = outfit.tags
            updatedAt = outfit.updatedAt!
            // createdAt は更新する必要なし
        }

        func toOutfit() async throws -> Outfit {
            return Outfit(
                id: id,
                // そのまま toItem による [Item] を items に渡したい
                itemIds: items.compactMapWithErrorLog(logger) { itemDto in
                    try itemDto.toItem().id
                },
                // usecase 側で imageSource, thumbnailSource を設定する。 なぜなら storage に画像が存在するか確認する必要があるが、ここでやってしまうと repository が storage に依存してしまうから
                imageSource: nil,
                thumbnailSource: nil,
                tags: tags,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }
}
