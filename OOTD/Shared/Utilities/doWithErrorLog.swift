//
//  doWithErrorLog.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/11.
//

import Foundation
import os



func doWithErrorLog<T>(_ f: () throws -> T, file: String = #file, line: Int = #line) -> T? {
    do {
        return try f()
    } catch {
        let name = (file as NSString).lastPathComponent
        logger.warning("\(error)\n\nat \(name):L\(line)")
        return nil
    }
}

func doWithErrorLog<T>(_ f: () async throws -> T, file: String = #file, line: Int = #line) async -> T? {
    do {
        return try await f()
    } catch {
        let name = (file as NSString).lastPathComponent
        logger.warning("\(error)\n\nat \(name):L\(line)")
        return nil
    }
}
