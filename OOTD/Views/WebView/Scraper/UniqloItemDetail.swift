//
//  UniqloItemDetail.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/08.
//

import Foundation
import SwiftSoup

private let logger = CustomLogger(#file)

struct UniqloItemDetail: EcItemDetail, FirstRetailingPage {
    let url: String
    let detail: ProductDetail
    let productCode: String
    let priceGroup: String
    
    struct ProductDetail: Codable {
        let result: Result
        
        struct Result: Codable {
            let images: Images
            let l1Ids: [String]
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
        url.matches(#"https://www\.uniqlo\.com/jp/ja/products/[A-Za-z0-9-]+/\d+(\?.*)?"#)
    }
    
    static func from(url detailUrl: String) async throws -> UniqloItemDetail {
        let productCode = try Self.getProductCode(detailUrl)
        let priceGroup = try Self.getPriceGroup(detailUrl)
        let apiUrl = "https://www.uniqlo.com/jp/api/commerce/v5/ja/products/\(productCode)/price-groups/\(priceGroup)/details"
        
        let data = try await request(apiUrl)
        let detail = try JSONDecoder().decode(ProductDetail.self, from: data)
        return .init(url: detailUrl, detail: detail, productCode: productCode, priceGroup: priceGroup)
    }
    
    static func getProductCode(_ detailUrl: String) throws -> String {
        // 正規表現パターン。URL全体のパターンの中で商品コード部分だけをキャプチャ
        let pattern = "https://www\\.uniqlo\\.com/jp/ja/products/([A-Z0-9]+-[A-Z0-9]+)/\\d+"
        
        let code = try detailUrl.extract(pattern)
        
        return code
    }
    
    static func getPriceGroup(_ detailUrl: String) throws -> String {
        // 正規表現パターン。URL全体のパターンの中で商品コード部分だけをキャプチャ
        let pattern = "https://www\\.uniqlo\\.com/jp/ja/products/[A-Z0-9]+-[A-Z0-9]+/(\\d+)"
        
        let group = try detailUrl.extract(pattern)
        
        return group
    }

    func name() throws -> String {
        detail.result.name
    }
    
    func imageUrls() throws -> [String] {
        var imageUrls: [String] = []
        
        let mainImageUrls = detail.result.images.main.map { $0.value.image }
        imageUrls.append(contentsOf: mainImageUrls)

        let subImageUrls = detail.result.images.sub.compactMap { $0.image }
        imageUrls.append(contentsOf: subImageUrls)
        
        imageUrls = imageUrls.map { removeAspectSuffix($0) }

        // also append other productCode images
        guard let productId = try? productCode.extract(#"E(\d+)-\d+"#) else {
            logger.warning("failed to extarct product id from \(productCode)")
            return imageUrls
        }
        
        for otherId in detail.result.l1Ids {
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
        let colorCode = try imageUrl.extract(pattern)
        return colorCode
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
    
    func brand() throws -> String {
        "UNIQLO"
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
