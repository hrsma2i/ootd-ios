//
//  request.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/24.
//

import Foundation

private let logger = getLogger(#file)

func request(_ urlString: String) async throws -> Data {
    logger.debug("request to \(urlString)")
    guard let url = URL(string: urlString) else {
        throw "URLが無効です: \(urlString)"
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw "HTTPリクエストが失敗しました: ステータスコード \(response)"
    }

    return data
}
