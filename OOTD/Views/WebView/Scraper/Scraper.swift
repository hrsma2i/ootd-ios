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
        guard let url = URL(string: urlString) else {
            throw "url is invalid: \(urlString)"
        }
        // 429 Too Many Requests にならないよう、キャッシュを有効化
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw "network error: invalid response for \(urlString)"
        }
        
        let html: String
        if let html_ = String(data: data, encoding: .utf8) {
            html = html_
        } else if let html_ = String(data: data, encoding: .shiftJIS) {
            html = html_
        } else {
            throw "network error: invalid data for \(urlString)"
        }
        
        let redirectedUrl = httpResponse.url
        
        return try .init(html, url: redirectedUrl?.absoluteString ?? urlString)
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
        
        urls = urls.unique()
        
        return urls
    }
    
    func defaultItems() async throws -> [Item] {
        let imageUrls = try await imageUrls()
        
        let items = imageUrls.map { imageUrl in
            Item(
                imageSource: .url(imageUrl),
                option: .init(
                    sourceUrl: url
                )
            )
        }
        return items
    }

    private func _items() async throws -> [Item] {
        switch domain {
        case .zozo:
            return try await itemsFromZOZO()

        case .uniqlo:
            return try await itemsFromUniqlo()

        case .gu:
            return try await itemsFromGu()
            
        default:
            return try await defaultItems()
        }
    }
    
    func items() async throws -> [Item] {
        var items = try await _items()
        items = items.unique()
        // TODO: サイズで足切りする？
        return items
    }
}
