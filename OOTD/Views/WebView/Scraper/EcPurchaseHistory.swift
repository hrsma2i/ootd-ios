//
//  EcPurchaseHistory.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/08.
//

import Foundation



protocol EcPurchaseHistory {
    static func isValidUrl(_ url: String) -> Bool

    func items() async throws -> [Item]
}

func generateEcPurchaseHisotry(html: String, url: String) throws -> any EcPurchaseHistory {
    if ZozoPurchaseHistory.isValidUrl(url) {
        return try ZozoPurchaseHistory(html: html, url: url)
    } else if GuPurchaseHistory.isValidUrl(url) {
        return try GuPurchaseHistory(html: html, url: url)
    } else if UniqloPurchaseHistory.isValidUrl(url) {
        return try UniqloPurchaseHistory(html: html, url: url)
    }

    throw "unsupported purchase history: \(url)"
}
