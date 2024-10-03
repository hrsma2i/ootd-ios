//
//  GuApi.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/03.
//

import Foundation

private let logger = getLogger(#file)

private struct ProductDetail: Codable {
    let result: Result

    struct Result: Codable {
        let images: Images

        struct Images: Codable {
            let sub: [Sub]

            struct Sub: Codable {
                let image: String?
            }
        }
    }
}

enum GuApi {
    static func imageUrlsFromDetail(detailUrl: String) async throws -> [String] {
        logger.debug("get image urls from gu detail")

        let productCode = try getProductCodeFromDetailUrl(detailUrl)
        let apiUrl = "https://www.gu-global.com/jp/api/commerce/v5/ja/products/\(productCode)/price-groups/00/details"

        let data = try await request(apiUrl)
        let productDetail = try JSONDecoder().decode(ProductDetail.self, from: data)

        let imageUrls = productDetail.result.images.sub.compactMap { $0.image }

        return imageUrls
    }

    static func getProductCodeFromDetailUrl(_ detailUrl: String) throws -> String {
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
}
