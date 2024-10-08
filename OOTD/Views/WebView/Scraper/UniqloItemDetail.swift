//
//  UniqloItemDetail.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/08.
//

import Foundation
import SwiftSoup

private let logger = getLogger(#file)

struct UniqloItemDetail: EcItemDetail {
    let url: String
    let productCode: String
    let priceGroup: String
    let scraper: Scraper
    let preloadedState: PreloadedState

    struct PreloadedState: Codable {
        let entity: Entity
        
        struct Entity: Codable {
            let pdpEntity: [String: Product_]
            
            struct Product_: Codable {
                let product: Product
                
                struct Product: Codable {
                    let images: Images
                    
                    struct Images: Codable {
                        let main: [String: Main]
                        let sub: [Sub]
                        
                        struct Main: Codable {
                            let image: String
                        }
                        
                        struct Sub: Codable {
                            let image: String
                        }
                    }
                }
            }
        }
    }
    
    static func isValidUrl(_ url: String) -> Bool {
        url.matches(#"https://www\.uniqlo\.com/jp/ja/products/[A-Za-z0-9-]+/\d+(\?.*)?"#)
    }
    
    static func from(url detailUrl: String) async throws -> UniqloItemDetail {
        let productCode = try Self.getProductCode(detailUrl)
        let priceGroup = try Self.getPriceGroup(detailUrl)
        let scraper = try await Scraper.from(url: detailUrl)
        let preloadedState = try Self.decodePreloadedState(scraper.doc)
        return .init(url: detailUrl, productCode: productCode, priceGroup: priceGroup, scraper: scraper, preloadedState: preloadedState)
    }
    
    static func decodePreloadedState(_ doc: SwiftSoup.Document) throws -> PreloadedState {
        let scripts = try doc.select("#root > script")
        // (?s)を追加して、dotallモードにより改行を含む文字列にもマッチ
        let pattern = #"(?s)window\.__PRELOADED_STATE__ = (\{.*?\})$"#
        
        for script in scripts {
            let scriptContent = try script.html()
            let regex = try NSRegularExpression(pattern: pattern, options: [])
                   
            guard let match = regex.firstMatch(in: scriptContent, options: [], range: NSRange(scriptContent.startIndex..., in: scriptContent)) else {
                continue
            }
            
            guard let range = Range(match.range(at: 1), in: scriptContent) else { continue }
            
            let jsonString = String(scriptContent[range])
                           
            guard let jsonData = jsonString.data(using: .utf8) else { continue }
                               
            let decoder = JSONDecoder()
            let state = try decoder.decode(PreloadedState.self, from: jsonData)
            
            return state
        }
        
        throw "failed to decode a preloaded state"
    }
    
    func imageUrls() throws -> [String] {
        let key = "\(productCode)-\(priceGroup)"

        var imageUrls: [String] = []
        
        guard let product_ = preloadedState.entity.pdpEntity[key] else {
            throw "no entity.pdpEntity.\(key) in the preloaded state"
        }
            
        let images = product_.product.images
            
        let mainImageUrls = images.main.map { $0.value.image }
        imageUrls.append(contentsOf: mainImageUrls)
            
        let subImageUrls = images.sub.map { $0.image }
        imageUrls.append(contentsOf: subImageUrls)
        
        guard !imageUrls.isEmpty else {
            throw "no image urls"
        }
        
        return imageUrls
    }
    
    static func getProductCode(_ detailUrl: String) throws -> String {
        // 正規表現パターン。URL全体のパターンの中で商品コード部分だけをキャプチャ
        let pattern = "https://www\\.uniqlo\\.com/jp/ja/products/([A-Z0-9]+-[A-Z0-9]+)/\\d+"
        
        let code = try extract(detailUrl, pattern: pattern)
        
        return code
    }
    
    static func getPriceGroup(_ detailUrl: String) throws -> String {
        // 正規表現パターン。URL全体のパターンの中で商品コード部分だけをキャプチャ
        let pattern = "https://www\\.uniqlo\\.com/jp/ja/products/[A-Z0-9]+-[A-Z0-9]+/(\\d+)"
        
        let group = try extract(detailUrl, pattern: pattern)
        
        return group
    }

    static func extract(_ detailUrl: String, pattern: String) throws -> String {
        // 正規表現オブジェクトを作成
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            throw "正規表現の作成に失敗しました"
        }
        
        let range = NSRange(detailUrl.startIndex ..< detailUrl.endIndex, in: detailUrl)
        
        // 最初のマッチを探す
        guard let match = regex.firstMatch(in: detailUrl, options: [], range: range) else {
            throw "商品コードが見つかりませんでした"
        }
        
        // キャプチャグループの範囲を取得
        guard let matchRange = Range(match.range(at: 1), in: detailUrl) else {
            throw "マッチ範囲が不正です"
        }
        
        // 商品コードを抽出
        let productCode = String(detailUrl[matchRange])
        
        return productCode
    }
    
    func categoryPath() throws -> [String] {
        throw "not implemented"
    }
    
    func description() throws -> String {
        throw "not implemented"
    }
    
    func price() throws -> Int {
        throw "not implemented"
    }
}
