//
//  ItemGridTab.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/16.
//

import Foundation

struct ItemGridTab: Hashable {
    let name: String
    var sort: Sort
    var filter: Filter?

    enum Sort: String, CaseIterable {
        case category = "カテゴリー順"
//        case purchasedOnDescendant = "購入日が新しい順"
//        case purchasedOnAscendant = "購入日が古い順"
        case createdAtDescendant = "作成日時が新しい順"
        case createdAtAscendant = "作成日時が古い順"

        func compare(_ lhs: Item, _ rhs: Item) -> Bool {
            switch self {
            case .category:
                lhs.category < rhs.category
//            case .purchasedOnDescendant:
//                !compareOptional(lhs.purchasedOn, rhs.purchasedOn)
//            case .purchasedOnAscendant:
//                compareOptional(lhs.purchasedOn, rhs.purchasedOn)
            case .createdAtDescendant:
                !compareOptional(lhs.createdAt, rhs.createdAt)
            case .createdAtAscendant:
                compareOptional(lhs.createdAt, rhs.createdAt)
            }
        }
    }

    struct Filter: Hashable {
        let category: Category?

        func callAsFunction(_ item: Item) -> Bool {
            true
                && (category == nil || item.category == category)
        }
    }

    func apply(_ items: [Item]) -> [Item] {
        var items = items

        if let filter {
            items = items.filter { filter($0) }
        }

        items = items.sorted {
            sort.compare($0, $1)
        }

        return items
    }
}
