//
//  Scraper+GU.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/15.
//

import Foundation

private let logger = getLogger(#file)

extension Scraper {
    private var isGuPurchaseHistory: Bool {
        url.hasPrefix("https://www.gu-global.com/jp/ja/member/purchase/history")
    }

    private func itemsFromGuPurchaseHistory() async throws -> [Item] {
        let anchors = try doc.select("#root > section > section > section > section.fr-ec-layout.fr-ec-layout--gutter-sm.fr-ec-layout--gutter-md.fr-ec-layout--gutter-lg.fr-ec-layout--span-4-sm.fr-ec-layout--span-12-md.fr-ec-layout--span-9-lg.fr-ec-template-information--min-height > ul > li > div.fr-ec-product-tile-resize-wrapper > a")

        guard anchors.count != 0 else {
            throw "anchors.count == 0"
        }

        let items = anchors.compactMapWithErrorLog(logger) { anchor in
            let img = try anchor.select("div.fr-ec-product-tile__horizontal-small-spacing-ec-renewal > div > div > img")

            let imageUrl = try img.attr("src")
            let sourceUrl = try anchor.attr("href")

            let divProductTileEnd = try anchor.select("div.fr-ec-product-tile__end.fr-ec-product-tile__end--padding-horizontal-small")

            let name = try divProductTileEnd.select("h3").text()

            let paragraphs = try divProductTileEnd.select("div > div > p")

            // CSS セレクタで取得しようとすると、カラーと購入日の<p>が同一のパスとみなされてしまうため、 text で判定する
            var color: String?
            var size: String?
            var purchasedOn: Date?
            for p in paragraphs {
                guard let text = try? p.text() else {
                    continue
                }

                if text.hasPrefix("カラー") {
                    color = text.replacingOccurrences(of: "カラー: ", with: "")
                } else if text.hasPrefix("サイズ") {
                    size = text.replacingOccurrences(of: "サイズ: ", with: "")
                } else if text.hasPrefix("購入日") {
                    let purchasedOnString = text
                        .replacingOccurrences(of: "購入日: ", with: "")
                    let f = DateFormatter()
                    f.dateFormat = "yyyy/MM/dd"
                    purchasedOn = f.date(from: purchasedOnString)
                }
            }

            return Item(
                imageSource: .url(imageUrl),
                option: .init(
                    name: name,
                    purchasedOn: purchasedOn,
                    sourceUrl: sourceUrl,
                    originalColor: color,
                    originalBrand: "GU",
                    originalSize: size
                )
            )
        }

        return items
    }

    private func isValidImageUrl(_ imageUrl: String) -> Bool {
        return imageUrl.matches(#"https://image.uniqlo.com/GU/ST3/(jp|AsianCommon)/imagesgoods/\d+/(item|sub)/(jpgoods|goods)_\d+_(sub)?\d+.*\.jpg"#)
    }

    func itemsFromGu() async throws -> [Item] {
        var items: [Item]
        if isGuPurchaseHistory {
            items = try await itemsFromGuPurchaseHistory()
        } else {
            items = try await defaultItems()
            items = items.compactMapWithErrorLog(logger) {
                guard let sourceUrl = $0.sourceUrl else {
                    throw "Item.sourceUrl is nil"
                }

                return Item(
                    imageSource: $0.imageSource,
                    option: .init(
                        sourceUrl: sourceUrl
                    )
                )
            }
        }

        // common post process
        items = items.filter {
            guard case let .url(imageUrl) = $0.imageSource else {
                return false
            }

            return isValidImageUrl(imageUrl)
        }

        return items
    }
}
