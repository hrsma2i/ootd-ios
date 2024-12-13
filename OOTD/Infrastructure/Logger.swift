//
//  Logger.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/26.
//

import Foundation
import os

struct CustomLogger {
    private var logger: Logger
    private var template: String

    init(_ category: String, template: String = "{message}") {
        self.logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "unknown", category: category)
        self.template = template
    }

    private func format(_ message: String) -> String {
        template.replacingOccurrences(of: "{message}", with: message)
    }

    func debug(_ message: String) {
        logger.debug("\(format(message))")
    }

    func info(_ message: String) {
        logger.info("\(format(message))")
    }

    func warning(_ message: String) {
        logger.warning("\(format(message))")
    }

    func error(_ message: String) {
        logger.error("\(format(message))")
    }
}
