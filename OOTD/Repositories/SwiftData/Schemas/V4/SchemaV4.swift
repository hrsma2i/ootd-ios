//
//  SchemaV4.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/27.
//

import Foundation
import SwiftData

struct SchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)
    static var models: [any PersistentModel.Type] {
        [SchemaV4.ItemDTO.self]
    }
}
