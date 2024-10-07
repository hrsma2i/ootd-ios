//
//  ZozoItemDetail.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/08.
//

import Foundation
import SwiftSoup

private let logger = getLogger(#file)

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

    func description() throws -> String {
        // PC 版に限る
        let description = try doc.select("#tabItemInfo > div > div.p-goods-information-note > div").text()

        return description
    }

    func price() throws -> Int {
        throw "It's impossisble to get price from zozo item detail page"
    }
}
