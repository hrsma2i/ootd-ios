//
//  ZozoItemDetail.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/08.
//

import Foundation
import SwiftSoup



struct ZozoItemDetail: EcItemDetail, ZozoPage {
    let url: String
    let html: String
    private let doc: SwiftSoup.Document

    init(html: String, url: String) throws {
        self.html = html
        doc = try SwiftSoup.parse(html)
        self.url = url
    }

    static func isValidUrl(_ url: String) -> Bool {
        // TODO: PC版に絞っていいかも
        url.matches(#"https://zozo\.jp/(sp/)?shop/[\w-]+/(goods-sale|goods)/\d+/(\?.*)?"#) || url.matches(#"https://zozo\.jp/(sp/)?\?c=gr&did=\d+"#)
    }

    func imageUrls() throws -> [String] {
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

    func name() throws -> String {
        let name = try doc.select("#goodsRight > div.p-goods-information__primary > h1").text()
        return name
    }

    func categoryPath() throws -> [String] {
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

    func colors() throws -> [String] {
        let spans = try doc.select("#goodsRight > div.cartBlock.clearfix > div > dl > dt > span")
        let colors = spans.compactMapWithErrorLog(logger) { try $0.text() }
        guard !colors.isEmpty else {
            throw "no color options"
        }
        return colors
    }

    func selectColorFromImage(_ imageUrl: String) throws -> String {
        // 画像URLに色情報が含まれていないので判定不可能
        throw "\(String(describing: Self.self)).\(#function) not implemented"
    }

    func brand() throws -> String {
        let brand = try doc.select("#goodsRight > div.p-goods-information__primary > div.p-goods-information-brand > a > div.p-goods-information-brand-link__label").text()
        return brand
    }

    func sizes() throws -> [String] {
        // #tblItemSize と table の間に div が挟まるパターンもあるので #tblItemSize 内のすべての table を取得する
        let sizes = try doc.select("#tblItemSize table:not([data-size-table=\"purchased\"]) > tbody > tr > th")
            .compactMapWithErrorLog(logger) {
                try $0.attr("data-size")
            }

        guard !sizes.isEmpty else {
            throw "no size options"
        }
        return sizes
    }

    func description() throws -> String {
        // PC 版に限る
        let description = try doc.select("#tabItemInfo > div > div.p-goods-information-note > div").text()

        return description
    }

    func price() throws -> Int {
        let priceString = try doc.select([
            "#goodsRight > div.p-goods-information__primary > div.p-goods-information__price",
            // セールの場合の元値
            "#goodsRight > div.p-goods-information__primary > div.p-goods-information__proper > span",
        ].joined(separator: ", ")).text()

        guard let price = Int(priceString
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "税込", with: "")
            .replacingOccurrences(of: ",", with: "")
        ) else {
            throw "failed to convert \(priceString) to Int"
        }

        return price
    }
}
