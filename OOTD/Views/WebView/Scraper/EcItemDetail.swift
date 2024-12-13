//
//  EcItemDetail.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/08.
//

import Foundation

private let logger = CustomLogger(#file)

protocol EcItemDetail {
    var url: String { get }

    static func isValidUrl(_ url: String) -> Bool

    func imageUrls() throws -> [String]

    func name() throws -> String

    func categoryPath() throws -> [String]

    func colors() throws -> [String]

    func selectColorFromImage(_ imageUrl: String) throws -> String

    func brand() throws -> String

    func sizes() throws -> [String]

    func description() throws -> String

    func price() throws -> Int
}

func generateEcItemDetail(html html_: String? = nil, url urlString_: String) async throws -> any EcItemDetail {
    let html: String
    let urlString: String

    if let html_ {
        html = html_
        urlString = urlString_
    } else {
        guard let url = URL(string: urlString_) else {
            throw "url is invalid: \(urlString_)"
        }
        // 429 Too Many Requests にならないよう、キャッシュを有効化
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw "network error: invalid response for \(urlString_)"
        }

        if let html_ = String(data: data, encoding: .utf8) {
            html = html_
        } else if let html_ = String(data: data, encoding: .shiftJIS) {
            html = html_
        } else {
            throw "network error: invalid data for \(urlString_)"
        }

        urlString = httpResponse.url?.absoluteString ?? urlString_

        if urlString != urlString_ {
            logger.debug("url redirected: \(urlString_) -> \(urlString)")
        }
    }

    if ZozoItemDetail.isValidUrl(urlString) {
        return try ZozoItemDetail(html: html, url: urlString)
    } else if GuItemDetail.isValidUrl(urlString) {
        return try await GuItemDetail.from(url: urlString)
    } else if UniqloItemDetail.isValidUrl(urlString) {
        return try await UniqloItemDetail.from(url: urlString)
    }

    throw "unsupported item detail page: \(urlString)"
}
