//
//  SwiftSoupDocumnet+.swift
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

struct SwiftSoupDocumentWrapper {
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
    
    private func _imageAndSourceUrls() async throws -> [(imageUrl: String, sourceUrl: String)] {
        func defaultCase() throws -> [(imageUrl: String, sourceUrl: String)] {
            let imgs = try doc.select("img")
            
            var imgUrls = imgs.compactMap {
                try? $0.attr("src")
            }
            
            imgUrls = imgUrls.map {
                if $0.hasPrefix("//") {
                    return "https:\($0)"
                } else if $0.hasPrefix("/") {
                    guard let host = URL(string: url)?.host else { return $0 }
                    return "https://\(host)\($0)"
                }
                return $0
            }
            
            let urls = imgUrls.map {
                (imageUrl: $0, sourceUrl: url)
            }
            
            return urls
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
            if url.hasPrefix("https://zozo.jp/sp/_member/orderhistory/") {
                let feedRows = try doc.select("#gArticle > div.gridIsland.gridIslandAdjacent.gridIslandBottomPadded > div:nth-child(2) > ul > li > div")
                let imgs = try doc.select("#gArticle > div.gridIsland.gridIslandAdjacent.gridIslandBottomPadded > div:nth-child(2) > ul > li > div > figure > div > div > a > img")
                let links = try doc.select("#gArticle > div.gridIsland.gridIslandAdjacent.gridIslandBottomPadded > div:nth-child(2) > ul > li > div > div > div > div.goodsH > a")
                
                guard feedRows.count != 0 else {
                    throw "feedRows.count == 0"
                }
                
                let urls = feedRows.compactMapWithErrorLog(logger) { row in
                    let img = try row.select("figure > div > div > a > img")
                    let link = try row.select("div > div > div.goodsH > a")

                    var imageUrl = try img.attr("src")
                    // 画像サイズを500に変更
                    let pattern = #"\d+(.jpg)"#
                    imageUrl = imageUrl.replacingOccurrences(of: pattern, with: "500$1", options: .regularExpression)
                    
                    var sourceUrl = try link.attr("href")
                    sourceUrl = sourceUrl.replacingOccurrences(of: "goods-sale", with: "goods")

                    return (imageUrl: imageUrl, sourceUrl: sourceUrl)
                }
                return urls
            } else {
                var urls = try defaultCase()
                urls = urls.compactMapWithErrorLog(logger) {
                    // 画像サイズを500に変更
                    let pattern = #"\d+(.jpg)"#
                    let imageUrl = $0.imageUrl.replacingOccurrences(of: pattern, with: "500$1", options: .regularExpression)
                    
                    let sourceUrl = $0.sourceUrl.replacingOccurrences(of: "goods-sale", with: "goods")
                    
                    return (imageUrl: imageUrl, sourceUrl: sourceUrl)
                }
                return urls
            }
            
        case .uniqlo:
            var urls = try defaultCase()
            let pattern = #"https://image.uniqlo.com/UQ/ST3/(jp|AsianCommon)/imagesgoods/\d+/item/(jpgoods|goods)_\d+_\d+.*\.jpg"#
            urls = urls.filter {
                $0.imageUrl.range(of: pattern, options: .regularExpression) != nil
            }
            return urls

        case .gu:
            var urls = try defaultCase()
            urls = urls.map {
                // remove query params
                let imageUrl = $0.imageUrl.split(separator: "?").first.map(String.init) ?? $0.imageUrl
                return (imageUrl: imageUrl, sourceUrl: $0.sourceUrl)
            }

            let pattern = #"https://image.uniqlo.com/GU/ST3/(jp|AsianCommon)/imagesgoods/\d+/item/(jpgoods|goods)_\d+_\d+.*\.jpg"#
            let pattern2 = #"https://image.uniqlo.com/GU/ST3/(jp|AsianCommon)/imagesgoods/\d+/sub/(jpgoods|goods)_\d+_sub\d+.*\.jpg"#
            urls = urls.filter {
                $0.imageUrl.range(of: pattern, options: .regularExpression) != nil
                    || $0.imageUrl.range(of: pattern2, options: .regularExpression) != nil
            }
            return urls

        default:
            return try defaultCase()
        }
    }
    
    func imageAndSourceUrls() async throws -> [(imageUrl: String, sourceUrl: String)] {
        var urls = try await _imageAndSourceUrls()
        var uniqueImageUrls = Set<String>()
        urls = urls.filter {
            if uniqueImageUrls.contains($0.imageUrl) {
                return false
            } else {
                uniqueImageUrls.insert($0.imageUrl)
                return true
            }
        }
        // TODO: サイズで足切りする？
        return urls
    }
}
