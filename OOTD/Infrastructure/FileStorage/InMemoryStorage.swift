//
//  InMemoryStorage.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/10.
//

import Foundation

class InMemoryStorage: FileStorage {
    private var storage: [String: Data] = [:]

    func save(data: Data, to path: String) async throws {
        storage[path] = data
    }

    func load(from path: String) async throws -> Data {
        guard let data = storage[path] else {
            throw "file not found for \(path)"
        }
        return data
    }

    func remove(at path: String) async throws {
        storage.removeValue(forKey: path)
    }

    func exists(at path: String) async throws -> Bool {
        return storage.keys.contains(path)
    }
}
