//
//  Logger.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/26.
//

import Foundation
import os

func getLogger(_ category: String) -> Logger {
    Logger(subsystem: Bundle.main.bundleIdentifier ?? "unknown", category: category)
}
