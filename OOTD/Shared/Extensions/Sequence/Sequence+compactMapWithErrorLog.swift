//
//  Sequence+compactMapWithErrorLog.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/10.
//

import Foundation

extension Sequence {
    func compactMapWithErrorLog<T>(_ logger: CustomLogger, _ transform: @escaping (Element) throws -> T) -> [T] {
        return compactMap {
            do {
                return try transform($0)
            } catch {
                logger.critical("\(error)")
                return nil
            }
        }
    }

    func asyncCompactMapWithErrorLog<T>(_ logger: CustomLogger, _ transform: @escaping (Element) async throws -> T) async -> [T] {
        return await withTaskGroup(of: T?.self) { group in
            var results: [T] = []

            for element in self {
                group.addTask {
                    do {
                        return try await transform(element)
                    } catch {
                        logger.critical("\(error.localizedDescription)")
                        return nil
                    }
                }
            }

            for await result in group {
                if let result = result {
                    results.append(result)
                }
            }

            return results
        }
    }
}
