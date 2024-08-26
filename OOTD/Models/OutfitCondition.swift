//
//  OutfitCondition.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/10.
//

import Foundation

struct OutfitFilter {
    var items: [Item] = []
}

struct OutfitCondition {
    var filter: OutfitFilter = .init()
}
