//
//  V1.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/26.
//

import Foundation
import SwiftData

struct SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [SchemaV1.ItemDTO.self]
    }
}
