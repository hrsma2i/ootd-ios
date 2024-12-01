//
//  AddItems.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/27.
//

import Foundation

struct AddItems {
    let repository: ItemRepository

    func callAsFunction(_ items: [Item]) async throws {
        try await repository.create(items)
    }
}
