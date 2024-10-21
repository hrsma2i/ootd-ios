//
//  SchemaV6.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/18.
//

import Foundation
import SwiftData

struct SchemaV6: VersionedSchema {
    static var versionIdentifier = Schema.Version(6, 0, 0)
    static var models: [any PersistentModel.Type] {
        [
            SchemaV6.ItemDTO.self,
            SchemaV6.OutfitDTO.self
        ]
    }
}
