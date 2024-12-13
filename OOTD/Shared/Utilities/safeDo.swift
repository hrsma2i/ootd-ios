//
//  doWithErrorLog.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/11.
//

import Foundation
import os

func safeDo<T>(_ f: () throws -> T, file: String = #file, function: String = #function, line: Int = #line) -> T? {
    do {
        return try f()
    } catch {
        logger.warning("\(error)", file: file, function: function, line: line)
        return nil
    }
}

func safeDo<T>(_ f: () async throws -> T, file: String = #file, function: String = #function, line: Int = #line) async -> T? {
    do {
        return try await f()
    } catch {
        logger.warning("\(error)", file: file, function: function, line: line)
        return nil
    }
}
