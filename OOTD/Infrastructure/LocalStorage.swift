//
//  LocalStorage.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/28.
//

import Foundation
import UIKit

private let logger = getLogger(#file)

struct LocalStorage {
    // https://gist.github.com/y-takagi/9f2cea659fb3f55b56aa04530bf0af39

    private let manager: FileManager
    private let directory: URL

    static let applicationSupport: LocalStorage = .init(.applicationSupportDirectory)
    static let documents: LocalStorage = .init(.documentDirectory)

    private init(_ directory: FileManager.SearchPathDirectory) {
        manager = FileManager.default
        self.directory = manager.urls(for: directory, in: .userDomainMask)[0]
    }

    func save(image: UIImage, to relPath: String) throws {
        guard let data = image.pngData() else {
            throw "failed to convert UIImage to Data"
        }
        try save(data: data, to: relPath)
    }

    func save(data: Data, to relPath: String) throws {
        let path = directory.appendingPathComponent(relPath)

        let saveDirectory = path.deletingLastPathComponent()
        try manager.createDirectory(at: saveDirectory, withIntermediateDirectories: true, attributes: nil)

        try data.write(to: path, options: Data.WritingOptions.atomic)
        logger.debug("[LocalStorage] save to \(path)")
    }

    func loadImage(from relPath: String) throws -> UIImage {
        let data = try load(from: relPath)
        guard let image = UIImage(data: data) else {
            throw "[LocalStorage] failed to convert Data to UIImage for path: \(relPath)"
        }
        return image
    }

    func load(from relPath: String) throws -> Data {
        let path = directory.appendingPathComponent(relPath)
        let data = try Data(contentsOf: path)
        return data
    }

    func remove(at relPath: String) throws {
        let path = directory.appendingPathComponent(relPath)
        try manager.removeItem(at: path)
        logger.debug("[LocalStorage] remove \(path)")
    }

    func exists(at relPath: String) -> Bool {
        let path = directory.appendingPathComponent(relPath)
        return manager.fileExists(atPath: path.path)
    }
}
