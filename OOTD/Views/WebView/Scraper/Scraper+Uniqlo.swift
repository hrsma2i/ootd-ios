//
//  Scraper+Uniqlo.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/15.
//

import Foundation

private let logger = getLogger(#file)

extension Scraper {
    private var isUniqloPurchaseHistory: Bool {
        url.hasPrefix("https://www.uniqlo.com/jp/ja/member/purchase/history")
    }

    private func itemsFromUniqloPurchaseHistory() async throws -> [Item] {
        let anchors = try doc.select("#root > section > section > section > section.fr-ec-layout.fr-ec-layout--gutter-sm.fr-ec-layout--gutter-md.fr-ec-layout--gutter-lg.fr-ec-layout--span-4-sm.fr-ec-layout--span-12-md.fr-ec-layout--span-9-lg.fr-ec-template-information--min-height > ul > li > div.fr-ec-product-tile-resize-wrapper > a")

        guard anchors.count != 0 else {
            throw "anchors.count == 0"
        }

        let items = anchors.compactMapWithErrorLog(logger) { anchor in
            let img = try anchor.select("div.fr-ec-product-tile__horizontal-small-spacing-ec-renewal > div > div > img")

            let imageUrl = try img.attr("src")
            let sourceUrl = try anchor.attr("href")

            return Item(imageURL: imageUrl, sourceUrl: sourceUrl)
        }

        return items
    }

    private func isValidImageUrl(_ imageUrl: String) -> Bool {
        return imageUrl.matches(#"https://image.uniqlo.com/UQ/ST3/(jp|AsianCommon)/imagesgoods/\d+/(item|sub)/(jpgoods|goods)_\d+_(sub)?\d+.*\.jpg"#)
    }

    func itemsFromUniqlo() async throws -> [Item] {
        var items: [Item]
        if isUniqloPurchaseHistory {
            items = try await itemsFromUniqloPurchaseHistory()
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
        items = items.filter { item in
            guard let imageUrl = item.imageURL else {
                return false
            }

            return isValidImageUrl(imageUrl)
        }

        return items
    }
}
