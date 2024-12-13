//
//  UniqloPurchaseHistory.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/08.
//

import Foundation
import SwiftSoup

private let logger = CustomLogger(#file)

struct UniqloPurchaseHistory: EcPurchaseHistory, FirstRetailingPage {
    let url: String
    let html: String
    private let doc: SwiftSoup.Document

    init(html: String, url: String) throws {
        self.html = html
        doc = try SwiftSoup.parse(html)
        self.url = url
    }

    static func isValidUrl(_ url: String) -> Bool {
        url.hasPrefix("https://www.uniqlo.com/jp/ja/member/purchase/history")
    }

    func items() async throws -> [Item] {
        let anchors = try doc.select("#root > section > section > section > section.fr-ec-layout.fr-ec-layout--gutter-sm.fr-ec-layout--gutter-md.fr-ec-layout--gutter-lg.fr-ec-layout--span-4-sm.fr-ec-layout--span-12-md.fr-ec-layout--span-9-lg.fr-ec-template-information--min-height > ul > li > div.fr-ec-product-tile-resize-wrapper > a")

        guard anchors.count != 0 else {
            throw "anchors.count == 0"
        }

        let items = anchors.compactMapWithErrorLog(logger) { anchor in
            let img = try anchor.select("div.fr-ec-product-tile__horizontal-small-spacing-ec-renewal > div > div > img")

            var imageUrl = try img.attr("src")
            imageUrl = removeAspectSuffix(imageUrl)

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
                    originalBrand: "UNIQLO",
                    originalSize: size
                )
            )
        }

        return items
    }
}
