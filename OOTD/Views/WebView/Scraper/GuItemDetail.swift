//
//  GuProductDetail.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/03.
//

import Foundation

private let logger = getLogger(#file)

struct GuItemDetail: EcItemDetail, FirstRetailingPage {
    let url: String
    let detail: ProductDetail
    
    struct ProductDetail: Codable {
        let result: Result
        
        struct Result: Codable {
            let images: Images
            let breadcrumbs: BreadCrumbs
            fileprivate let longDescription: String
            let prices: Prices
            
            struct BreadCrumbs: Codable {
                let gender: Gender
                let class_: Class_
                let category: GuItemDetail.ProductDetail.Result.BreadCrumbs.Category
                let subcategory: SubCategory
                
                enum CodingKeys: String, CodingKey {
                    case gender
                    case class_ = "class"
                    case category
                    case subcategory
                }
                
                struct Gender: Codable {
                    let locale: String
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
            
            struct Images: Codable {
                let main: [String: Main]
                let sub: [Sub]
                
                struct Main: Codable {
                    let image: String
                }
                
                struct Sub: Codable {
                    let image: String?
                }
            }
            
            struct Prices: Codable {
                let base: Base
                
                struct Base: Codable {
                    let value: Int
                }
            }
        }
    }
    
    static func isValidUrl(_ url: String) -> Bool {
        url.matches(#"https://www\.gu-global\.com/jp/ja/products/[A-Za-z0-9-]+/\d+(\?.*)?"#)
    }
    
    static func from(url detailUrl: String) async throws -> GuItemDetail {
        let productCode = try Self.getProductCode(detailUrl)
        let apiUrl = "https://www.gu-global.com/jp/api/commerce/v5/ja/products/\(productCode)/price-groups/00/details"
        
        let data = try await Self.request(apiUrl)
        let detail = try JSONDecoder().decode(ProductDetail.self, from: data)
        return .init(url: detailUrl, detail: detail)
    }
    
    func imageUrls() throws -> [String] {
        var imageUrls: [String] = []
        
        let mainImageUrls = detail.result.images.main.map { $0.value.image }
        imageUrls.append(contentsOf: mainImageUrls)

        let subImageUrls = detail.result.images.sub.compactMap { $0.image }
        imageUrls.append(contentsOf: subImageUrls)
        
        imageUrls = imageUrls.map { removeAspectSuffix($0) }

        return imageUrls
    }
    
    static func getProductCode(_ detailUrl: String) throws -> String {
        // 正規表現パターン。URL全体のパターンの中で商品コード部分だけをキャプチャ
        let pattern = "https://www\\.gu-global\\.com/jp/ja/products/([A-Z0-9]+-[A-Z0-9]+)/\\d+"
        
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
    
    static func request(_ urlString: String) async throws -> Data {
        logger.debug("request to \(urlString)")
        // URLを生成
        guard let url = URL(string: urlString) else {
            throw "URLが無効です: \(urlString)"
        }
        
        // URLリクエストを送信し、データを取得
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // HTTPレスポンスのステータスコードを確認
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw "HTTPリクエストが失敗しました: ステータスコード \(response)"
        }
        
        return data
    }
    
    func name() throws -> String {
        throw "not implemented"
    }

    func categoryPath() throws -> [String] {
        [
            detail.result.breadcrumbs.class_.locale,
            detail.result.breadcrumbs.category.locale,
            detail.result.breadcrumbs.subcategory.locale,
        ]
    }
    
    func colors() throws -> [String] {
        throw "not implemented"
    }
    
    func selectColorFromImage(_ imageUrl: String) throws -> String {
        throw "not implemented"
    }

    func brand() throws -> String {
        throw "not implemented"
    }

    func sizes() throws -> [String] {
        throw "not implemented"
    }

    func description() throws -> String {
        detail.result.longDescription.replacingOccurrences(of: "<br>", with: "\n")
    }
    
    func price() throws -> Int {
        detail.result.prices.base.value
    }
}
