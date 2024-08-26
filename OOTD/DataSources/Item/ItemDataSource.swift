//
//  ItemDataSource.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/07/14.
//

import Foundation

protocol ItemDataSource {
    func fetch() async throws -> [Item]

    func create(_ items: [Item]) async throws -> [Item]

    func update(_ items: [Item]) async throws

    func delete(_ items: [Item]) async throws
}
