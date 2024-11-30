//
//  InMemorySearchItems.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/28.
//

import Foundation

struct InMemorySearchItems: SearchItems {
    let items: [Item]

    func callAsFunction(query: ItemQuery, searchText: String? = nil) async throws -> [Item] {
        var items = items

        // TODO: searchText も ItemQuery に持たせたほうが良さそう？
        if let searchText {
            let keyword = searchText.lowercased()

            if keyword != "" {
                items = items.filter { item in
                    item.name.lowercased().contains(keyword)
                        || item.originalDescription?.lowercased().contains(keyword) ?? false
                        || item.originalBrand?.lowercased().contains(keyword) ?? false
                        || item.tags.map {
                            $0.lowercased().contains(keyword)
                        }.contains(true)
                }
            }
        }

        if let filter = query.filter {
            items = items.filter { filter($0) }
        }

        items = items.sorted {
            query.sort.compare($0, $1)
        }

        return items
    }
}

private extension ItemQuery.Filter {
    func callAsFunction(_ item: Item) -> Bool {
        true
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
