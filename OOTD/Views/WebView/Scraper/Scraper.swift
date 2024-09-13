//
//  Scraper.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/07/24.
//

import Foundation
import SwiftSoup

private let logger = getLogger(#file)

enum URLDomain: String, CaseIterable {
    case zozo = "zozo.jp"
    case uniqlo = "uniqlo.com"
    case gu = "gu-global.com"
//    case instagram = "instagram.com"
}

struct Scraper {
    let doc: SwiftSoup.Document
    let url: String
    let html: String
    
    init(_ html: String, url: String) throws {
        self.html = html
        doc = try SwiftSoup.parse(html)
        self.url = url
    }
    
    var domain: URLDomain? {
        guard let host = URL(string: url)?.host else { return nil }
        
        for domain in URLDomain.allCases {
            if host.contains(domain.rawValue) {
                return domain
            }
        }

        return nil
    }

    static func from(url urlString: String) async throws -> Self {
        let url = URL(string: urlString)!
        // 429 Too Many Requests にならないよう、キャッシュを有効化
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw "network error: invalid response for \(urlString)"
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw "network error: invalid data for \(urlString)"
        }
        
        return try .init(html, url: urlString)
    }
    
    func ogImageURL() throws -> String {
        guard let ogImageURL = try doc.select("meta[property=og:image]").first()?.attr("content") else {
            throw "no og:image in \(url)\n\(html)"
        }
        
        return ogImageURL
    }
    
    func faviconURL() throws -> String {
        let links: Elements = try doc.select("link")
        
        // rel属性が "icon" または "shortcut icon" の<link>要素を抽出する
        guard let faviconLink = links.first(where: { element in
            guard let rel = try? element.attr("rel") else { return false }
            guard let href = try? element.attr("href") else { return false }
            
            return (rel.contains("icon") || rel.contains("shortcut icon")) && !href.contains("svg")
        }) else {
            throw "no link with rel=\"icon\" or \"shorcut icon\" in \(url)"
        }
        
        let faviconURL = try faviconLink.attr("href")
        
        // 相対パスの場合はドメインを最初に追加する
        if faviconURL.starts(with: "/"), let domain = URL(string: url)?.host {
            return "https://\(domain)\(faviconURL)"
        }
        
        return faviconURL
    }
    
//    var deeplink: String? {
//        switch domain {
//        case .instagram:
//            return try? doc.select("meta[property=al:ios:url]").first()?.attr("content")
//        default:
//            return nil
//        }
//    }
    
    func imageUrls() async throws -> [String] {
        let imgs = try doc.select("img")
        
        var urls = imgs.compactMap {
            try? $0.attr("src")
        }
        
        // relative path to absolute path
        urls = urls.map {
            if $0.hasPrefix("//") {
                return "https:\($0)"
            } else if $0.hasPrefix("/") {
                guard let host = URL(string: url)?.host else { return $0 }
                return "https://\(host)\($0)"
            }
            return $0
        }
        
        // deduplicate
        urls = Array(Set(urls))
        
        return urls
    }
    
    private func _items() async throws -> [Item] {
        func defaultCase() async throws -> [Item] {
            let imageUrls = try await imageUrls()
            
            let items = imageUrls.map {
                Item(imageURL: $0, sourceUrl: url)
            }
            return items
        }
        
        switch domain {
//        case .instagram:
//            do {
//                return try await Instagram.getImageURLsFromMediaURL(url)
//            } catch {
//                logger.error("\(error.localizedDescription)")
//                return try defaultCase()
//            }
        case .zozo:
            let args: [(imageUrl: String, sourceUrl: String)]
            if url.hasPrefix("https://zozo.jp/sp/_member/orderhistory/") {
                let feedRows = try doc.select("#gArticle > div.gridIsland.gridIslandAdjacent.gridIslandBottomPadded > div:nth-child(2) > ul > li > div")
                
                guard feedRows.count != 0 else {
                    throw "feedRows.count == 0"
                }
                
                args = feedRows.compactMapWithErrorLog(logger) { row in
                    let img = try row.select("figure > div > div > a > img")
                    let link = try row.select("div > div > div.goodsH > a")

                    var imageUrl = try img.attr("src")
                    imageUrl = resize(imageUrl)
                    
                    var sourceUrl = try link.attr("href")
                    sourceUrl = removeSale(sourceUrl)

                    return (imageUrl: imageUrl, sourceUrl: sourceUrl)
                }
            } else {
                let items = try await defaultCase()
                args = items.compactMapWithErrorLog(logger) {
                    guard let imageUrl = $0.imageURL, let sourceUrl = $0.sourceUrl else {
                        throw "Item imageURL or sourceUrl is nil"
                    }
                    
                    // TODO: filter valid image urls like c.imgz.jp

                    return (imageUrl: imageUrl, sourceUrl: sourceUrl)
                }
            }
            
            func resize(_ imageUrl: String, size: Int = 500) -> String {
                imageUrl.replacingOccurrences(of: #"\d+(.jpg)"#, with: "\(size)$1", options: .regularExpression)
            }
            
            func removeSale(_ sourceUrl: String) -> String {
                sourceUrl.replacingOccurrences(of: "goods-sale", with: "goods")
            }
            
            let items = args.map {
                let imageUrl = resize($0.imageUrl)
                let sourceUrl = removeSale($0.sourceUrl)
                return Item(imageURL: imageUrl, sourceUrl: sourceUrl)
            }
            
            return items

        case .uniqlo:
            var items = try await defaultCase()
            let pattern = #"https://image.uniqlo.com/UQ/ST3/(jp|AsianCommon)/imagesgoods/\d+/item/(jpgoods|goods)_\d+_\d+.*\.jpg"#
            items = items.filter {
                $0.imageURL?.range(of: pattern, options: .regularExpression) != nil
            }
            return items

        case .gu:
            var items = try await defaultCase()
            items = items.map {
                // remove query params
                let imageUrl = $0.imageURL?.split(separator: "?").first.map(String.init) ?? $0.imageURL
                return Item(imageURL: imageUrl, sourceUrl: $0.sourceUrl)
            }

            let pattern = #"https://image.uniqlo.com/GU/ST3/(jp|AsianCommon)/imagesgoods/\d+/item/(jpgoods|goods)_\d+_\d+.*\.jpg"#
            let pattern2 = #"https://image.uniqlo.com/GU/ST3/(jp|AsianCommon)/imagesgoods/\d+/sub/(jpgoods|goods)_\d+_sub\d+.*\.jpg"#
            items = items.filter {
                $0.imageURL?.range(of: pattern, options: .regularExpression) != nil
                    || $0.imageURL?.range(of: pattern2, options: .regularExpression) != nil
            }
            return items

        default:
            return try await defaultCase()
        }
    }
    
    func items() async throws -> [Item] {
        var items = try await _items()
        // deduplicate
        items = Array(Set(items))
        // TODO: サイズで足切りする？
        return items
    }
}
