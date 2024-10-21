//
//  main.swift
//  OOTDCLI
//
//  Created by Hiroshi Matsui on 2024/10/21.
//

import Foundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "unknown", category: #file)

let fileManager = FileManager.default

let home = FileManager.default.homeDirectoryForCurrentUser
let schemasPath = "\(home.path)/XCodeProjects/OOTD/OOTD/DataSources/SwiftData/Schemas"
logger.debug("\(schemasPath)")

// Schemas ディレクトリ内の V で始まるディレクトリを取得
let versionDirectories = try fileManager.contentsOfDirectory(atPath: schemasPath)
    .filter { $0.hasPrefix("V") }

// 最新のバージョン N を取得
let versionNumbers = versionDirectories.compactMap { dir -> Int? in
    let numberString = dir.dropFirst(1) // "V" を取り除いた部分を取得
    return Int(numberString)
}

guard let latestVersion = versionNumbers.max() else {
    logger.debug("No version directories found.")
    exit(1)
}

let newVersion = latestVersion + 1
let newVersionDirectoryName = "V\(newVersion)"
let newVersionDirectoryPath = "\(schemasPath)/\(newVersionDirectoryName)"

// 最新バージョンのディレクトリをコピーして新しいバージョンのディレクトリを作成
let latestVersionDirectoryPath = "\(schemasPath)/V\(latestVersion)"

try fileManager.copyItem(atPath: latestVersionDirectoryPath, toPath: newVersionDirectoryPath)
logger.debug("Copied \(latestVersionDirectoryPath) to \(newVersionDirectoryPath)")

// 新しいディレクトリ内のファイル名およびファイル内の内容を置換
let newVersionFiles = try fileManager.contentsOfDirectory(atPath: newVersionDirectoryPath)

for file in newVersionFiles {
    let oldFilePath = "\(newVersionDirectoryPath)/\(file)"
    let newFileName = file.replacingOccurrences(of: "\(latestVersion)", with: "\(newVersion)")
    let newFilePath = "\(newVersionDirectoryPath)/\(newFileName)"

    // ファイル名をリネーム
    try fileManager.moveItem(atPath: oldFilePath, toPath: newFilePath)
    logger.debug("Renamed \(oldFilePath) to \(newFilePath)")

    // ファイル内のテキスト内容も置換
    var fileContents = try String(contentsOfFile: newFilePath)
    fileContents = fileContents.replacingOccurrences(of: "V\(latestVersion)", with: "V\(newVersion)")
    fileContents = fileContents.replacingOccurrences(of: "Schema.Version(\(latestVersion)", with: "Schema.Version(\(newVersion)")
    try fileContents.write(toFile: newFilePath, atomically: true, encoding: .utf8)
    logger.debug("Updated content in \(newFilePath)")
}

logger.debug("Successfully created new version V\(newVersion).")
