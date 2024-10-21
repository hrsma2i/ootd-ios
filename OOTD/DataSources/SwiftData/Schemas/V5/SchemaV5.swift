//
//  SchemaV5.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/18.
//

import Foundation
import SwiftData

struct SchemaV5: VersionedSchema {
    static var versionIdentifier = Schema.Version(5, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            SchemaV5.ItemDTO.self,
            SchemaV5.OutfitDTO.self
        ]
    }
}
