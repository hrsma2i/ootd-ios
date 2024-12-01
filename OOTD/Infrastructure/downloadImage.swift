//
//  downloadImage.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/26.
//

import Foundation
import UIKit

func download(_ urlString: String) async throws -> Data {
    guard let url = URL(string: urlString) else {
        throw "invalid url: \(urlString)"
    }

    let (data, _) = try await URLSession.shared.data(from: url)

    return data
}

func downloadImage(_ urlString: String) async throws -> UIImage {
    let data = try await download(urlString)
    guard let image = UIImage(data: data) else {
        throw "failed to convert downloaded data to UIImage"
    }

    return image
}
