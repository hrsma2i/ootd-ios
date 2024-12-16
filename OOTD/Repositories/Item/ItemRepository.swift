//
//  ItemRepository.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/07/14.
//

import Foundation

protocol ItemRepository {
    func findAll() async throws -> [Item]

    // error のときも入力の item の情報がほしいので Result 型は使わない
    func save(_ items: [Item]) async throws -> [(item: Item, error: Error?)]

    func delete(_ items: [Item]) async throws
}
