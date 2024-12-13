//
//  Logger.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/26.
//

import Foundation
import os

let logger = CustomLogger.shared

struct CustomLogger {
    private var logger: Logger
    private var template: String

    static let shared = CustomLogger()

    struct Fields {
        let file: String
        let function: String
        let line: Int

        var fileStem: String {
            let basename = URL(fileURLWithPath: file).lastPathComponent
            let stem = basename.replacingOccurrences(of: ".swift", with: "")
            return stem
        }

        var funcName: String {
            function.split(separator: "(").first.map { String($0) } ?? function
        }
    }

    private init(template: String = "{message}") {
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "unknown", category: "unknown")
        self.template = template
    }

    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fields = Fields(file: file, function: function, line: line)
        log(level: .debug, message: message, fields: fields)
    }

    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fields = Fields(file: file, function: function, line: line)
        log(level: .error, message: message, fields: fields)
    }

    func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fields = Fields(file: file, function: function, line: line)
        log(level: .fault, message: message, fields: fields)
    }

    private func log(level: OSLogType, message: String, fields: Fields) {
        let formatted = format(message, fields: fields)

        switch level {
        case .error:
            logger.warning("\(formatted)")
        case .fault:
            logger.fault("\(formatted)")
        default:
            logger.debug("\(formatted)")
        }
    }

    private func format(_ message: String, fields: Fields) -> String {
        var s = template.replacingOccurrences(of: "{message}", with: message)
        s = "[\(fields.fileStem).\(fields.funcName):L\(fields.line)] \(s)"
        return s
    }
}
