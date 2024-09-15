//
//  Scraper+ZOZO.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/13.
//

import Foundation

private let logger = getLogger(#file)

extension Scraper {
    private var isZOZOPurchaseHistory: Bool {
        url.hasPrefix("https://zozo.jp/sp/_member/orderhistory/")
    }

    private func itemsFromZOZOPurchaseHistory() async throws -> [Item] {
        let feedRows = try doc.select("#gArticle > div.gridIsland.gridIslandAdjacent.gridIslandBottomPadded > div:nth-child(2) > ul > li > div")

        guard feedRows.count != 0 else {
            throw "feedRows.count == 0"
        }

        let items = feedRows.compactMapWithErrorLog(logger) { row in
            let img = try row.select("figure > div > div > a > img")
            let link = try row.select("div > div > div.goodsH > a")

            let imageUrl = try img.attr("src")
            let sourceUrl = try link.attr("href")

            return Item(imageURL: imageUrl, sourceUrl: sourceUrl)
        }

        return items
    }

    private func resize(_ imageUrl: String, size: Int = 500) -> String {
        imageUrl.replacingOccurrences(of: #"\d+(.jpg)"#, with: "\(size)$1", options: .regularExpression)
    }

    private func removeSale(_ sourceUrl: String) -> String {
        sourceUrl.replacingOccurrences(of: "goods-sale", with: "goods")
    }

    private func isValidImageUrl(_ imageUrl: String) -> Bool {
        imageUrl.hasPrefix("https://c.imgz.jp/") ||
            imageUrl.hasPrefix("https://o.imgz.jp/")
    }

    func itemsFromZOZO() async throws -> [Item] {
        var items: [Item]
        if isZOZOPurchaseHistory {
            items = try await itemsFromZOZOPurchaseHistory()
        } else {
            items = try await defaultItems()
            items = items.compactMapWithErrorLog(logger) {
                guard let imageUrl = $0.imageURL, let sourceUrl = $0.sourceUrl else {
                    throw "Item imageURL or sourceUrl is nil"
                }

                return Item(imageURL: imageUrl, sourceUrl: sourceUrl)
            }
        }

        // common post process
        items = items.compactMapWithErrorLog(logger) { item in
            guard var imageUrl = item.imageURL else {
                throw "imageUrl is nil"
            }

            guard isValidImageUrl(imageUrl) else {
                throw "imageUrl is invalid: \(imageUrl)"
            }

            guard var sourceUrl = item.sourceUrl else {
                throw "sourceUrl is nil"
            }

            imageUrl = resize(imageUrl)
            sourceUrl = removeSale(sourceUrl)
            return Item(imageURL: imageUrl, sourceUrl: sourceUrl)
        }

        return items
    }
}
