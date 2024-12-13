//
//  Config.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/08/07.
//

import Foundation

private let logger = CustomLogger(#file)

enum Config {
    static var DATA_SOURCE: RepositoryType {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "Data Source") as? String else {
            logger.critical("failed to get Data Source from Info.plist. SampleRepository is used.")
            return .sample
        }

        guard let repository = RepositoryType(rawValue: value) else {
            logger.critical("unknown Repository: \(value). SampleRepository is used")
            return .sample
        }

        return repository
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

    static var IS_DEBUG_MODE: Bool {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "Debug Mode") as? String else {
            fatalError("failed to get Debug Mode from Info.plist")
        }

        return value == "true"
    }

    static var IS_SHOW_AD: Bool {
        let key = "Show Ad"
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            fatalError("failed to get \(key) from Info.plist")
        }

        return value == "true"
    }

    static var GOOGLE_ADMOB_AD_UNIT_ID: String {
        let key = "Google AdMob Ad Unit ID"
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            fatalError("failed to get  \(key) from Info.plist")
        }

        return value
    }
}
