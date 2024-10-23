//
//  OutfitGridTab.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/16.
//

import Foundation

struct OutfitGridTab: Hashable {
    let name: String
    var sort: Sort
    var filter: Filter = .init()

    enum Sort: String, CaseIterable {
        case createdAtDescendant = "作成日時が新しい順"
        case createdAtAscendant = "作成日時が古い順"

        func compare(_ lhs: Outfit, _ rhs: Outfit) -> Bool {
            switch self {
            case .createdAtDescendant:
                !compareOptional(lhs.createdAt, rhs.createdAt)
            case .createdAtAscendant:
                compareOptional(lhs.createdAt, rhs.createdAt)
            }
        }
    }

    struct Filter: Hashable {
        var items: [Item] = []

        func callAsFunction(_ outfit: Outfit) -> Bool {
            true
                && items.allSatisfy { item in outfit.items.contains { $0.id == item.id } }
        }
    }

    func apply(_ outfits: [Outfit]) -> [Outfit] {
        var outfits = outfits

        outfits = outfits.filter { filter($0) }

        outfits = outfits.sorted {
            sort.compare($0, $1)
        }

        return outfits
    }
}
