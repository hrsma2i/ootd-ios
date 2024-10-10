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
            let colors: [Color]
            let name: String
            fileprivate let longDescription: String
            let prices: Prices
            let sizes: [Size]
            
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
            
            struct Color: Codable {
                let displayCode: String
                let name: String
                
                var codeAndName: String {
                    "\(displayCode) \(name)"
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
            
            struct Size: Codable {
                let name: String
            }
        }
    }
    
    static func isValidUrl(_ url: String) -> Bool {
        url.matches(#"https://www\.gu-global\.com/jp/ja/products/[A-Za-z0-9-]+/\d+(\?.*)?"#)
    }
    
    static func from(url detailUrl: String) async throws -> GuItemDetail {
        let productCode = try Self.getProductCode(detailUrl)
        let priceGroup = try Self.getPriceGroup(detailUrl)
        let apiUrl = "https://www.gu-global.com/jp/api/commerce/v5/ja/products/\(productCode)/price-groups/\(priceGroup)/details"
        
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
        let pattern = #"https://www\.gu-global\.com/jp/ja/products/([A-Z0-9]+-[A-Z0-9]+)/\d+"#
        let code = try detailUrl.extract(pattern)
        return code
    }
    
    static func getPriceGroup(_ detailUrl: String) throws -> String {
        let pattern = #"https://www\.gu-global\.com/jp/ja/products/[A-Z0-9]+-[A-Z0-9]+/(\d+)"#
        let group = try detailUrl.extract(pattern)
        return group
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
        detail.result.name
    }

    func categoryPath() throws -> [String] {
        [
            detail.result.breadcrumbs.class_.locale,
            detail.result.breadcrumbs.category.locale,
            detail.result.breadcrumbs.subcategory.locale,
        ]
    }
    
    func colors() throws -> [String] {
        detail.result.colors.map { $0.codeAndName }
    }
    
    func selectColorFromImage(_ imageUrl: String) throws -> String {
        // main 画像のみ対応。 sub画像のURLにはカラーコードが含まれないので画像から色を判定できない。
        let colorCode = try Self.getColorCode(imageUrl)
        guard let color = detail.result.colors.filter({ $0.displayCode == colorCode }).first else {
            throw "no color options matching the image"
        }
        return color.codeAndName
    }
    
    static func getColorCode(_ imageUrl: String) throws -> String {
        let pattern = #"https://image\.uniqlo\.com/GU/ST3/AsianCommon/imagesgoods/\d+/item/goods_(\d+)_\d+(_3x4)?.jpg"#
        let colorCode = try imageUrl.extract(pattern)
        return colorCode
    }

    func brand() throws -> String {
        "GU"
    }

    func sizes() throws -> [String] {
        detail.result.sizes.map { $0.name }
    }

    func description() throws -> String {
        detail.result.longDescription.replacingOccurrences(of: "<br>", with: "\n")
    }
    
    func price() throws -> Int {
        detail.result.prices.base.value
    }
}
