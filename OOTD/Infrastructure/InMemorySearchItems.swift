//
//  InMemorySearchItems.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/28.
//

import Foundation

struct InMemorySearchItems: SearchItems {
    let items: [Item]

    func callAsFunction(query: ItemQuery) async throws -> [Item] {
        var items = items

        items = items.filter { query.filter.matches($0) }

        items = items.sorted {
            query.sort.compare($0, $1)
        }

        return items
    }

    func callAsFunction(text: String) async throws -> [Item] {
        var items = items

        items = items.filter { ItemQuery.Filter.matchesSearchText(item: $0, text: text) }

        return items
    }
}

private extension ItemQuery.Filter {
    static func matchesSearchText(item: Item, text: String?) -> Bool {
        guard let text, text != "" else {
            return true
        }

        let keyword = text.lowercased()

        return item.name.lowercased().contains(keyword)
            || item.originalDescription?.lowercased().contains(keyword) ?? false
            || item.originalBrand?.lowercased().contains(keyword) ?? false
            || item.tags.map {
                $0.lowercased().contains(keyword)
            }.contains(true)
    }

    func matches(_ item: Item) -> Bool {
        return true
            && Self.matchesSearchText(item: item, text: searchText)
            && (category == nil || item.category == category)
    }
}

private extension ItemQuery.Sort {
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
