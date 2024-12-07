//
//  FileStorage.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/07.
//

import Foundation
import UIKit

protocol FileStorage {
    func save(data: Data, to: String) async throws

    func load(from: String) async throws -> Data

    func remove(at: String) async throws

    func exists(at: String) async throws -> Bool
}

extension FileStorage {
    func saveImage(image: UIImage, to: String) async throws {
        guard let data = image.pngData() else {
            throw "failed to convert UIImage to Data"
        }
        try await save(data: data, to: to)
    }

    func loadImage(from: String) async throws -> UIImage {
        let data = try await load(from: from)
        guard let image = UIImage(data: data) else {
            throw "failed to convert Data to UIImage for path: \(from)"
        }
        return image
    }
}
