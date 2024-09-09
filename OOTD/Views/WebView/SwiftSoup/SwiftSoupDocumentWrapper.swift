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
    
    private func _imageURLs() async throws -> [String] {
        func defaultCase() throws -> [String] {
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
            
            return imgUrls
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
            let urls = try defaultCase()
            let goodsImageUrls = urls.filter {
                $0.hasPrefix("https://c.imgz.jp")
            }
            
            // 画像サイズを500に変更
            let pattern = #"\d+(.jpg)"#
            let scaledUrls = goodsImageUrls.map {
                $0.replacingOccurrences(of: pattern, with: "500$1", options: .regularExpression)
            }
            return scaledUrls
        
        case .uniqlo:
            let urls = try defaultCase()
            let pattern = #"https://image.uniqlo.com/UQ/ST3/(jp|AsianCommon)/imagesgoods/\d+/item/(jpgoods|goods)_\d+_\d+.*\.jpg"#
            let validUrls = urls.filter {
                $0.range(of: pattern, options: .regularExpression) != nil
            }
            return validUrls

        case .gu:
            let urls = try defaultCase()
            let urlsWoQueryParams = urls.map {
                // remove query params
                $0.split(separator: "?").first.map(String.init) ?? $0
            }

            let pattern = #"https://image.uniqlo.com/GU/ST3/(jp|AsianCommon)/imagesgoods/\d+/item/(jpgoods|goods)_\d+_\d+.*\.jpg"#
            let pattern2 = #"https://image.uniqlo.com/GU/ST3/(jp|AsianCommon)/imagesgoods/\d+/sub/(jpgoods|goods)_\d+_sub\d+.*\.jpg"#
            let validUrls = urlsWoQueryParams.filter {
                $0.range(of: pattern, options: .regularExpression) != nil
                    || $0.range(of: pattern2, options: .regularExpression) != nil
            }
            return validUrls

        default:
            return try defaultCase()
        }
    }
    
    func imageURLs() async throws -> [String] {
        let urls = try await _imageURLs()
        let deduplicatedUrls = Array(Set(urls))
        // TODO: サイズ順にする？それともサイズで足切りする？
        let sortedUrls = deduplicatedUrls.sorted()
        return sortedUrls
    }
}
