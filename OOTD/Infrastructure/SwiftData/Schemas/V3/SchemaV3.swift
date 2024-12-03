//
//  SchemaV3.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/27.
//

import Foundation
import SwiftData

struct SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] {
        [SchemaV3.ItemDTO.self]
    }
}
