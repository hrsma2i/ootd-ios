//
//  LocalStorage.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/28.
//

import Foundation
import UIKit

private let logger = getLogger(#file)

enum LocalStorage {
    // https://gist.github.com/y-takagi/9f2cea659fb3f55b56aa04530bf0af39

    private static let manager = FileManager.default
    private static let directory = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]

    static func save(image: UIImage, to relPath: String) throws {
        guard let data = image.pngData() else {
            throw "failed to convert UIImage to Data"
        }
        try save(data: data, to: relPath)
    }

    static func save(data: Data, to relPath: String) throws {
        let path = directory.appendingPathComponent(relPath)

        let saveDirectory = path.deletingLastPathComponent()
        try manager.createDirectory(at: saveDirectory, withIntermediateDirectories: true, attributes: nil)

        try data.write(to: path, options: Data.WritingOptions.atomic)
        logger.debug("[LocalStorage] save to \(path)")
    }

    static func loadImage(from relPath: String) throws -> UIImage {
        let data = try load(from: relPath)
        guard let image = UIImage(data: data) else {
            throw "[LocalStorage] failed to convert Data to UIImage for path: \(relPath)"
        }
        return image
    }

    static func load(from relPath: String) throws -> Data {
        let path = directory.appendingPathComponent(relPath)

        guard let data = try? Data(contentsOf: path) else {
            throw "[LocalStorage] failed to load data from \(path)"
        }

        return data
    }
}
