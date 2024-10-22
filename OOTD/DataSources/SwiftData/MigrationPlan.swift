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
        [
            SchemaV1.self,
            SchemaV2.self,
            SchemaV3.self,
            SchemaV4.self,
            SchemaV5.self,
            SchemaV6.self,
            SchemaV7.self,
        ]
    }

    static var stages: [MigrationStage] {
        [
            migrateV1toV2,
            migrateV2toV3,
            migrateV3toV4,
            migrateV4toV5,
            migrateV5toV6,
            migrateV6toV7,
        ]
    }

    static let migrateV6toV7: MigrationStage = .lightweight(
        fromVersion: SchemaV6.self,
        toVersion: SchemaV7.self
    )

    static let migrateV5toV6: MigrationStage = .lightweight(
        fromVersion: SchemaV5.self,
        toVersion: SchemaV6.self
    )

    static let migrateV4toV5: MigrationStage = .lightweight(
        fromVersion: SchemaV4.self,
        toVersion: SchemaV5.self
    )

    static let migrateV3toV4: MigrationStage = .lightweight(
        fromVersion: SchemaV3.self,
        toVersion: SchemaV4.self
    )

    static let migrateV2toV3: MigrationStage = .lightweight(
        fromVersion: SchemaV2.self,
        toVersion: SchemaV3.self
    )

    static let migrateV1toV2: MigrationStage = .lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
