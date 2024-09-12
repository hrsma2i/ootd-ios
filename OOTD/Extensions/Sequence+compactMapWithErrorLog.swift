//
//  Sequence+compactMapWithErrorLog.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/10.
//

import Foundation
import os

extension Sequence {
    func compactMapWithErrorLog<T>(_ logger: Logger, _ transform: @escaping (Element) throws -> T) -> [T] {
        return compactMap {
            do {
                return try transform($0)
            } catch {
                logger.error("\(error)")
                return nil
            }
        }
    }
}
