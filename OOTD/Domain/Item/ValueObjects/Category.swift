//
//  Category.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/26.
//

import Foundation

enum Category: String, Codable, CaseIterable, Comparable {
    case halfInnerTops = "Tシャツ・半袖シャツ"
    case longInnerTops = "シャツ・ロンT"
    case middleTops = "ニット・スウェット"
    case outerwear = "アウター"
    case bottoms = "ボトムス"
    case shoes = "シューズ"
    case others = "その他"
    case uncategorized = "未分類"

    static var allCasesWithoutUncategorized: [Category] {
        allCases.filter { $0 != .uncategorized }
    }

    static func < (lhs: Category, rhs: Category) -> Bool {
        guard let lhsIndex = allCases.firstIndex(of: lhs),
              let rhsIndex = allCases.firstIndex(of: rhs)
        else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}
