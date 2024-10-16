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

    enum Sort {
        case category,
             purchasedOn,
             createdAt

        func compare(_ lhs: Item, _ rhs: Item) -> Bool {
            switch self {
            case .category:
                lhs.category < rhs.category
            case .purchasedOn:
                compareOptional(lhs.purchasedOn, rhs.purchasedOn)
            case .createdAt:
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

func compareOptional<T: Comparable>(_ lhs: T?, _ rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
        return false // 両方が nil の場合、順序は変えない
    case (nil, _):
        return true // 左側が nil の場合、左が先
    case (_, nil):
        return false // 右側が nil の場合、右が先
    case (let lhsValue?, let rhsValue?):
        return lhsValue < rhsValue // 両方が非 nil の場合、通常の比較
    }
}
