//
//  ItemDTO.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/26.
//

import Foundation
import SwiftData

extension SchemaV1 {
    @Model
    class ItemDTO {
        typealias OutfitDTO = SchemaV5.OutfitDTO

        @Attribute(.unique) var id: String
        var category: String
        var sourceUrl: String?
        @Relationship(inverse: \OutfitDTO.items) var outfits: [OutfitDTO]

        // create 時のみ使う。 update, delete 時は .fetchSingle() を使う。
        // なぜなら、すでに container 内に保存済みのDTOと同じ id のDTOを生成すると、 DTO.id の参照時に EXC_BREAKPOINT のエラーが発生してしまうから。
        // この原因は id に @Attribute(.unique) 制約があるから。なので、すでに保存済み（update, delete）の場合は container から取得する。
        init(item: Item) {
            id = item.id
            category = item.category.rawValue
            sourceUrl = item.sourceUrl
            outfits = []
        }
    }
}
