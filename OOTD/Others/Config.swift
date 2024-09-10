//
//  Config.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/08/07.
//

import Foundation

private let logger = getLogger(#file)

enum Config {
    static var DATA_SOURCE: DataSourceType {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "Data Source") as? String else {
            logger.error("failed to get Data Source from Info.plist. SampleDataSource is used.")
            return .sample
        }

        guard let dataSource = DataSourceType(rawValue: value) else {
            logger.error("unknown DataSource: \(value). SampleDataSource is used")
            return .sample
        }

        return dataSource
    }

    static var BUILD_CONFIG: String {
        #if DEBUG
        return "Debug"
        #elseif RELEASE
        return "Release"
        #else
        return "unknown"
        #endif
    }
}
