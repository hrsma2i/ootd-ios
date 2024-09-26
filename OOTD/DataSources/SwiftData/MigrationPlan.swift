//
//  MigrationPlan.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/26.
//

import Foundation
import SwiftData

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    static let migrateV1toV2: MigrationStage = .lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
