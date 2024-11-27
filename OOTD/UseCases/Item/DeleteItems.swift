//
//  DeleteItems.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/27.
//

import Foundation

struct DeleteItems {
    let repository: ItemRepository

    func callAsFunction(_ items: [Item]) async throws {
        try await repository.delete(items)
    }
}
