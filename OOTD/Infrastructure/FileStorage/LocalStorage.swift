//
//  LocalStorage.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/28.
//

import Foundation
import UIKit

private let logger = CustomLogger(#file)

struct LocalStorage: FileStorage {
    // https://gist.github.com/y-takagi/9f2cea659fb3f55b56aa04530bf0af39

    private let manager: FileManager
    private let directory: URL

    static let applicationSupport: LocalStorage = .init(.applicationSupportDirectory)
    static let documents: LocalStorage = .init(.documentDirectory)

    private init(_ directory: FileManager.SearchPathDirectory) {
        manager = FileManager.default
        self.directory = manager.urls(for: directory, in: .userDomainMask)[0]
    }

    func save(data: Data, to relPath: String) async throws {
        let path = directory.appendingPathComponent(relPath)

        let saveDirectory = path.deletingLastPathComponent()
        try manager.createDirectory(at: saveDirectory, withIntermediateDirectories: true, attributes: nil)

        try data.write(to: path, options: Data.WritingOptions.atomic)
        logger.debug("[LocalStorage] save to \(path)")
    }

    func load(from relPath: String) async throws -> Data {
        let path = directory.appendingPathComponent(relPath)
        let data = try Data(contentsOf: path)
        return data
    }

    func remove(at relPath: String) async throws {
        let path = directory.appendingPathComponent(relPath)
        try manager.removeItem(at: path)
        logger.debug("[LocalStorage] remove \(path)")
    }

    func exists(at relPath: String) async throws -> Bool {
        let path = directory.appendingPathComponent(relPath)
        return manager.fileExists(atPath: path.path)
    }
}
