//
//  UniqloItemDetail.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/08.
//

import Foundation
import SwiftSoup

private let logger = getLogger(#file)

struct UniqloItemDetail: EcItemDetail, FirstRetailingPage {
    let url: String
    let productCode: String
    let priceGroup: String
    let scraper: Scraper
    let preloadedState: PreloadedState
    let product: PreloadedState.Entity.Product_.Product
    
    struct PreloadedState: Codable {
        let entity: Entity
        
        struct Entity: Codable {
            let pdpEntity: [String: Product_]
            
            struct Product_: Codable {
                let product: Product
                
                struct Product: Codable {
                    let breadcrumbs: BreadCrumbs
                    let colors: [Color]
                    let designDetail: String
                    let images: Images
                    // 同一商品としてまとめられる商品番号
                    let l1Ids: [String]
                    let name: String
                    let prices: Prices
                    let sizes: [Size]
                    
                    struct BreadCrumbs: Codable {
                        let class_: Class_
                        let category: GuItemDetail.ProductDetail.Result.BreadCrumbs.Category
                        let subcategory: SubCategory
                        
                        enum CodingKeys: String, CodingKey {
                            case class_ = "class"
                            case category
                            case subcategory
                        }
                        
                        struct Class_: Codable {
                            let locale: String
                        }
                        
                        struct Category: Codable {
                            let locale: String
                        }
                        
                        struct SubCategory: Codable {
                            let locale: String
                        }
                    }
                    
                    struct Color: Codable {
                        let displayCode: String
                        let name: String
                        
                        var codeAndName: String {
                            "\(displayCode) \(name)"
                        }
                    }

                    struct Images: Codable {
                        let main: [String: Main]
                        
                        struct Main: Codable {
                            let image: String
                        }
                    }
                    
                    struct Prices: Codable {
                        let base: Base
                        
                        struct Base: Codable {
                            let value: Int
                        }
                    }
                    
                    struct Size: Codable {
                        let name: String
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
        let key = "\(productCode)-\(priceGroup)"
        guard let product_ = preloadedState.entity.pdpEntity[key] else {
            throw "no entity.pdpEntity.\(key) in the preloaded state"
        }
        return .init(
            url: detailUrl,
            productCode: productCode,
            priceGroup: priceGroup,
            scraper: scraper,
            preloadedState: preloadedState,
            product: product_.product
        )
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

    static func extract(_ s: String, pattern: String) throws -> String {
        // 正規表現オブジェクトを作成
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            throw "正規表現の作成に失敗しました"
        }
        
        let range = NSRange(s.startIndex ..< s.endIndex, in: s)
        
        // 最初のマッチを探す
        guard let match = regex.firstMatch(in: s, options: [], range: range) else {
            throw "商品コードが見つかりませんでした"
        }
        
        // キャプチャグループの範囲を取得
        guard let matchRange = Range(match.range(at: 1), in: s) else {
            throw "マッチ範囲が不正です"
        }
        
        // 商品コードを抽出
        let productCode = String(s[matchRange])
        
        return productCode
    }
    
    func name() throws -> String {
        product.name
    }
    
    func imageUrls() throws -> [String] {
        var imageUrls: [String] = []
        
        let images = product.images
            
        let mainImageUrls = images.main.map { $0.value.image }
        imageUrls.append(contentsOf: mainImageUrls)
        
        // also append other productCode images
        guard let productId = try? Self.extract(productCode, pattern: #"E(\d+)-\d+"#) else {
            logger.warning("failed to extarct product id from \(productCode)")
            return imageUrls
        }
        
        for otherId in product.l1Ids {
            guard otherId != productId else { continue }
            
            let otherImageUrls = mainImageUrls.map {
                $0.replacingOccurrences(of: productId, with: otherId)
            }
            imageUrls.append(contentsOf: otherImageUrls)
        }
            
        guard !imageUrls.isEmpty else {
            throw "no image urls"
        }
        
        imageUrls = imageUrls.map {
            removeAspectSuffix($0)
        }
        
        imageUrls = imageUrls.unique()
        
        imageUrls = sortImageUrlsByColor(imageUrls)
        
        return imageUrls
    }
    
    func sortImageUrlsByColor(_ imageUrls: [String]) -> [String] {
        return imageUrls.compactMap { imageUrl -> (url: String, color: String)? in
            guard let color = try? Self.getColorCode(imageUrl) else {
                return nil
            }
            return (url: imageUrl, color: color)
        }.sorted {
            $0.color < $1.color
        }.map {
            $0.url
        }
    }
    
    static func getColorCode(_ imageUrl: String) throws -> String {
        let pattern = #"https://image\.uniqlo\.com/UQ/ST3/AsianCommon/imagesgoods/\d+/item/goods_(\d+)_\d+(_3x4)?.jpg"#
        let colorCode = try Self.extract(imageUrl, pattern: pattern)
        return colorCode
    }
    
    func categoryPath() throws -> [String] {
        [
            product.breadcrumbs.class_.locale,
            product.breadcrumbs.category.locale,
            product.breadcrumbs.subcategory.locale,
        ]
    }
    
    func colors() throws -> [String] {
        product.colors.map { $0.codeAndName }
    }
    
    func selectColorFromImage(_ imageUrl: String) throws -> String {
        let colorCode = try Self.getColorCode(imageUrl)
        guard let color = product.colors.filter({ $0.displayCode == colorCode }).first else {
            throw "no color options matching the image"
        }
        return color.codeAndName
    }
    
    func brand() throws -> String {
        "UNIQLO"
    }
    
    func sizes() throws -> [String] {
        product.sizes.map { $0.name }
    }
    
    func description() throws -> String {
        product.designDetail.replacingOccurrences(of: "<br>", with: "\n")
    }
    
    func price() throws -> Int {
        product.prices.base.value
    }
}
