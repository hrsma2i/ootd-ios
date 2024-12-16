//
//  GetItems.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/27.
//

import Foundation

struct GetItems {
    let repository: ItemRepository

    @MainActor
    func callAsFunction() async throws -> [Item] {
        let items = try await repository.findAll()
        return items
    }
}
