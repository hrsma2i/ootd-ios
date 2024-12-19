//
//  LocalStorage.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/28.
//

import Foundation
import UIKit

struct LocalStorage: FileStorage {
    // https://gist.github.com/y-takagi/9f2cea659fb3f55b56aa04530bf0af39

    private let manager: FileManager
    private let directory: FileManager.SearchPathDirectory
    private let url: URL
    private let basePath: String

    static let applicationSupport: LocalStorage = .init(.applicationSupportDirectory)
    static let documentsBuckup = LocalStorage(.documentDirectory, basePath: "backup")

    private init(_ directory: FileManager.SearchPathDirectory, basePath: String = "") {
        manager = FileManager.default
        self.directory = directory
        url = try! manager.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: true)
        self.basePath = basePath
    }

    var id: String {
        let directoryName: String
        switch directory {
        case .applicationSupportDirectory:
            directoryName = "ApplicationSupport"
        case .documentDirectory:
            directoryName = "Document"
        default:
            directoryName = "Unknown"
        }

        return "\(String(describing: Self.self))/\(directoryName)/\(basePath)"
    }

    func save(data: Data, to relPath: String) async throws {
        let path = fullPath(relPath)

        let saveDirectory = path.deletingLastPathComponent()
        try manager.createDirectory(at: saveDirectory, withIntermediateDirectories: true, attributes: nil)

        try data.write(to: path, options: Data.WritingOptions.atomic)
        logger.debug("save to \(path)")
    }

    func load(from relPath: String) async throws -> Data {
        let path = fullPath(relPath)
        let data = try Data(contentsOf: path)
        return data
    }

    func remove(at relPath: String) async throws {
        let path = fullPath(relPath)
        try manager.removeItem(at: path)
        logger.debug("remove \(path)")
    }

    func exists(at relPath: String) async throws -> Bool {
        let path = fullPath(relPath)
        return manager.fileExists(atPath: path.path)
    }

    private func fullPath(_ relPath: String) -> URL {
        let relPath = "\(basePath)/\(relPath)"
        return url.appendingPathComponent(relPath)
    }
}
