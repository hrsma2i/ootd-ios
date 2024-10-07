//
//  DefaultPurchaseHistory.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/08.
//

import Foundation

struct DefaultPurchaseHistory: EcPurchaseHistory {
    private let scraper: Scraper

    init(html: String, url: String) throws {
        scraper = try Scraper(html, url: url)
    }

    static func isValidUrl(_ url: String) -> Bool {
        true
    }

    func items() throws -> [Item] {
        let imageUrls = try scraper.imageUrls()

        let items = imageUrls.map { imageUrl in
            Item(
                imageSource: .url(imageUrl),
                option: .init(
                    sourceUrl: scraper.url
                )
            )
        }
        return items
    }
}
