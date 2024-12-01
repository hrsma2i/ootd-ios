//
//  ItemQuery.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/16.
//

import Foundation

struct ItemQuery: Hashable, Identifiable {
    let id = UUID()
    let name: String
    var sort: Sort
    var filter: Filter = .init()

    enum Sort: String, CaseIterable {
        case category = "カテゴリー順"
//        case purchasedOnDescendant = "購入日が新しい順"
//        case purchasedOnAscendant = "購入日が古い順"
        case createdAtDescendant = "作成日時が新しい順"
        case createdAtAscendant = "作成日時が古い順"
    }

    struct Filter: Hashable {
        var searchText: String?
        var category: Category?
    }
}
