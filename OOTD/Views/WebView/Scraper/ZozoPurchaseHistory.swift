//
//  ZozoPurchaseHistory.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/08.
//

import Foundation
import SwiftSoup

private let logger = CustomLogger(#file)

struct ZozoPurchaseHistory: EcPurchaseHistory, ZozoPage {
    let url: String
    let html: String
    private let doc: SwiftSoup.Document

    init(html: String, url: String) throws {
        self.html = html
        doc = try SwiftSoup.parse(html)
        self.url = url
    }

    static func isValidUrl(_ url: String) -> Bool {
        url.hasPrefix("https://zozo.jp/sp/_member/orderhistory/")
    }

    func items() async throws -> [Item] {
        let orders = try doc.select("#gArticle > div.gridIsland.gridIslandAdjacent.gridIslandBottomPadded > div:has(ul)")

        var items: [Item] = []

        for order in orders {
            do {
                let purchasedOnString = try order.select("div > dl:nth-child(1) > dd").text()
                let f = DateFormatter()
                f.dateFormat = "yyyy.MM.dd"
                let purchasedOn = f.date(from: purchasedOnString)

                let feedRows = try order.select("ul > li > div")

                guard feedRows.count != 0 else {
                    throw "feedRows.count == 0"
                }

                let itemsInOrder = await feedRows.asyncCompactMapWithErrorLog(logger) { row -> Item in
                    // だいたいが div > a > img だが、もう売ってない昔の商品などは div > img になることもあるので div 以下の img にしてある
                    let img = try row.select("figure > div > div img")
                    var imageUrl = try img.attr("src")
                    guard isValidImageUrl(imageUrl) else {
                        throw "invalid image url: \(imageUrl)"
                    }
                    imageUrl = resize(imageUrl)

                    let goodsOutline = try row.select("div > div")

                    let priceString = try goodsOutline.select("div.goodsPrice > span.goodsPriceAmount").text()
                    let price = Int(priceString.replacingOccurrences(of: "¥", with: "")
                        .replacingOccurrences(of: ",", with: ""))

                    let link = try goodsOutline.select("div.goodsH > a")
                    var sourceUrl = try link.attr("href")
                    sourceUrl = removeSale(sourceUrl)

                    let name = try link.text()

                    let colorAndSize = try? goodsOutline.select("div.goodsKind").text()
                    let components = colorAndSize?.split(separator: "/")
                    let color: String?
                    let size: String?
                    if let components, components.count == 2 {
                        color = components[0].trimmingCharacters(in: .whitespaces)
                        size = components[1].trimmingCharacters(in: .whitespaces)
                    } else {
                        color = nil
                        size = nil
                    }

                    let brand = try? goodsOutline.select("div.goodsBrand").text()

                    return Item(
                        imageSource: .url(imageUrl),
                        option: .init(
                            name: name,
                            purchasedPrice: price,
                            purchasedOn: purchasedOn,
                            sourceUrl: sourceUrl,
                            originalColor: color,
                            originalBrand: brand,
                            originalSize: size
                        )
                    )
                }

                items.append(contentsOf: itemsInOrder)
            } catch {
                logger.warning("\(error)")
            }
        }

        return items
    }
}
