//
//  SearchItems.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/28.
//

import Foundation

protocol SearchItems {
    // DDD の QueryService に相当する。
    // N+1問題を回避したいし、データソースごとに最適なクエリを投げたいが、
    // Repository に検索ロジックを持たせて複雑にしたくないので、インターフェースを UseCases/ に定義し、
    // 実装は Infrastructure/ に、データソースごとに用意する。
    func callAsFunction(query: ItemQuery) async throws -> [Item]
}
