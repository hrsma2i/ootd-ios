//
//  downloadImage.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/26.
//

import Foundation
import UIKit

func downloadImage(_ urlString: String) async throws -> Data {
    guard let url = URL(string: urlString) else {
        throw "invalid url: \(urlString)"
    }

    let (data, _) = try await URLSession.shared.data(from: url)

    return data
}
