//
//  Array+asyncMap.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/01.
//

import Foundation

extension Array {
    func asyncMap<T>(isParallel: Bool = true, _ transform: @escaping (Element) async throws -> T) async rethrows -> [T] {
        var results = [T]()

        if isParallel {
            results.reserveCapacity(count)

            try await withThrowingTaskGroup(of: T.self) { group in
                for element in self {
                    group.addTask {
                        try await transform(element)
                    }
                }

                for try await result in group {
                    results.append(result)
                }
            }
        } else {
            for element in self {
                let result = try await transform(element)
                results.append(result)
            }
        }

        return results
    }

    func asyncCompactMap<T>(isParallel: Bool = true, _ transform: @escaping (Element) async -> T?) async -> [T] {
        // asyncMapを使って変換し、その後でnilをフィルタリング
        let mappedResults = await asyncMap(isParallel: isParallel) { element in
            await transform(element)
        }

        // nilをフィルタリングして結果を返す
        return mappedResults.compactMap { $0 }
    }
}
