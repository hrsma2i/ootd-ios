//
//  ItemRepository.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/07/14.
//

import Foundation

protocol ItemRepository {
    func findAll() async throws -> [Item]

    func save(_ items: [Item]) async throws

    func delete(_ items: [Item]) async throws
}
