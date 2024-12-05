//
//  InMemorySearchOutfits.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/28.
//

import Foundation

struct InMemorySearchOutfits: SearchOutfits {
    let outfits: [Outfit]

    func callAsFunction(query: OutfitQuery) async throws -> [Outfit] {
        var outfits = outfits

        outfits = outfits.filter { query.filter.matches($0) }

        outfits = outfits.sorted {
            query.sort.compare($0, $1)
        }

        return outfits
    }

    func callAsFunction(text: String) async throws -> [Outfit] {
        var outfits = outfits

        outfits = outfits.filter { OutfitQuery.Filter.matchesSearchText(outfit: $0, text: text) }

        return outfits
    }

    func callAsFunction(usingAny items: [Item]) async throws -> [Outfit] {
        outfits.filter { outfit in
            outfit.items.contains { item in items.contains { $0.id == item.id }}
        }
    }
}

private extension OutfitQuery.Filter {
    static func matchesSearchText(outfit: Outfit, text: String?) -> Bool {
        guard let text, text != "" else {
            return true
        }

        let keyword = text.lowercased()

        return outfit.items.map {
            $0.name.lowercased().contains(keyword)
        }.contains(true)
            || outfit.tags.map {
                $0.lowercased().contains(keyword)
            }.contains(true)
    }

    func matches(_ outfit: Outfit) -> Bool {
        true
            && Self.matchesSearchText(outfit: outfit, text: searchText)
            && items.allSatisfy { item in outfit.items.contains { $0.id == item.id } }
    }
}

private extension OutfitQuery.Sort {
    func compare(_ lhs: Outfit, _ rhs: Outfit) -> Bool {
        switch self {
        case .createdAtDescendant:
            !compareOptional(lhs.createdAt, rhs.createdAt)
        case .createdAtAscendant:
            compareOptional(lhs.createdAt, rhs.createdAt)
        }
    }
}
