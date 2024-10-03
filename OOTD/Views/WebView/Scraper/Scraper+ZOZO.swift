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

    var isZozoGoodsDetail: Bool {
        return url.matches(#"https://zozo\.jp/(sp/)?shop/[\w-]+/(goods-sale|goods)/\d+/(\?.*)?"#) || url.matches(#"https://zozo\.jp/(sp/)?\?c=gr&did=\d+"#)
    }

    private func itemsFromZOZOPurchaseHistory() async throws -> [Item] {
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
                    let img = try row.select("figure > div > div > a > img")
                    let imageUrl = try img.attr("src")

                    let goodsOutline = try row.select("div > div")

                    let priceString = try goodsOutline.select("div.goodsPrice > span.goodsPriceAmount").text()
                    let price = Int(priceString.replacingOccurrences(of: "¥", with: "")
                        .replacingOccurrences(of: ",", with: ""))

                    let link = try goodsOutline.select("div.goodsH > a")
                    let sourceUrl = try link.attr("href")

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

    func categoryPathFromZozoGoodsDetail() throws -> [String] {
        guard isZozoGoodsDetail else {
            throw "not ZOZO goods detail page: \(url)"
        }

        // PC 版に限る
        let infoSpecList = try doc.select("#tabItemInfo > div > div.p-goods-information-spec > div:nth-child(1) > dl")

        guard let categoryList = infoSpecList.first(where: {
            guard let dt = try? $0.select("dt"),
                  let key = try? dt.text()
            else {
                return false
            }
            return key.contains("カテゴリー")
        }) else {
            throw "no category info in zozo goods detail page"
        }

        let anchors = try categoryList.select("dd > ol > li > a")

        let categoryPath = anchors.compactMapWithErrorLog(logger) {
            try $0.text()
        }

        return categoryPath
    }

    func descriptionFromZozoGoodsDetail() throws -> String {
        guard isZozoGoodsDetail else {
            throw "not ZOZO goods detail page: \(url)"
        }

        // PC 版に限る
        let description = try doc.select("#tabItemInfo > div > div.p-goods-information-note > div").text()

        return description
    }

    func imageUrlsFromZozoGoodsDetail() throws -> [String] {
        guard isZozoGoodsDetail else {
            throw "not ZOZO goods detail page: \(url)"
        }

        // PC 版に限る
        let imgs = try doc.select("#photoThimb > li.p-goods-thumbnail-list__item > div > span.p-goods-photograph__image-container > img")
        let imageUrls = imgs.compactMapWithErrorLog(logger) {
            var url = try $0.attr("data-main-image-src")
            guard isValidImageUrl(url) else {
                throw "image url is invalid \(url)"
            }
            url = resize(url)
            return url
        }

        return imageUrls
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
        items = items.compactMapWithErrorLog(logger) { item in
            guard case var .url(imageUrl) = item.imageSource else {
                throw "imageSource is not url"
            }

            guard isValidImageUrl(imageUrl) else {
                throw "imageUrl is invalid: \(imageUrl)"
            }

            guard var sourceUrl = item.sourceUrl else {
                throw "sourceUrl is nil"
            }

            imageUrl = resize(imageUrl)
            sourceUrl = removeSale(sourceUrl)
            return item.copyWith(\.imageSource, value: .url(imageUrl))
                .copyWith(\.sourceUrl, value: sourceUrl)
        }

        return items
    }
}
