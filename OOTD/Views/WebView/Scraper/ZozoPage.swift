//
//  ZozoPage.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/08.
//

import Foundation

protocol ZozoPage {}

extension ZozoPage {
    func resize(_ imageUrl: String, size: Int = 500) -> String {
        imageUrl.replacingOccurrences(of: #"\d+(.jpg)"#, with: "\(size)$1", options: .regularExpression)
    }

    func removeSale(_ sourceUrl: String) -> String {
        sourceUrl.replacingOccurrences(of: "goods-sale", with: "goods")
    }

    func isValidImageUrl(_ imageUrl: String) -> Bool {
        imageUrl.hasPrefix("https://c.imgz.jp/") ||
            imageUrl.hasPrefix("https://o.imgz.jp/")
    }
}
