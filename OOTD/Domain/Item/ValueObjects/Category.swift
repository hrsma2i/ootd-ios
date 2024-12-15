//
//  Category.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/26.
//

import Foundation

// 将来的に英語版対応や、ユーザー定義カテゴリーの拡張を考慮し、 enum ではなく struct にしている
struct Category: Codable, Comparable, Hashable {
    let id: Int
    let displayName: String

    static let lightShortSleeveTops = Category(id: 1, displayName: "Tシャツ・半袖シャツ")
    static let lightLongSleeveTops = Category(id: 2, displayName: "シャツ・ロンT")
    static let heavyTops = Category(id: 3, displayName: "ニット・スウェット")
    static let outerwear = Category(id: 4, displayName: "アウター")
    static let bottoms = Category(id: 5, displayName: "ボトムス")
    static let shoes = Category(id: 6, displayName: "シューズ")
    static let others = Category(id: 999, displayName: "その他")
    static let uncategorized = Category(id: 1000, displayName: "未分類")

    static let allCases: [Category] = [
        .lightShortSleeveTops,
        .lightLongSleeveTops,
        .heavyTops,
        .outerwear,
        .bottoms,
        .shoes,
        .others,
        .uncategorized
    ]

    private init(id: Int, displayName: String) {
        self.id = id
        self.displayName = displayName
    }

    init?(rawValue: Int) {
        guard let category = Self.allCases.first(where: { $0.id == rawValue }) else {
            return nil
        }
        self = category
    }

    init?(displayName: String) {
        guard let category = Self.allCases.first(where: { $0.displayName == displayName }) else {
            return nil
        }
        self = category
    }

    static var allCasesWithoutUncategorized: [Category] {
        return allCases.filter { $0 != .uncategorized }
    }

    static func < (lhs: Category, rhs: Category) -> Bool {
        // id ではなく allCases の順番で比較
        guard let lhsIndex = allCases.firstIndex(of: lhs),
              let rhsIndex = allCases.firstIndex(of: rhs)
        else {
            return false
        }

        return lhsIndex < rhsIndex
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(displayName)
    }

    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.id == rhs.id && lhs.displayName == rhs.displayName
    }
}
