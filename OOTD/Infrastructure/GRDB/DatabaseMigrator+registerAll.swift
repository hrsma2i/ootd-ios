//
//  Migrations.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/17.
//

import Foundation
import GRDB

protocol Migration {
    var name: String { get }

    func callAsFunction(_ db: Database) throws
}

extension DatabaseMigrator {
    mutating func registerAll() throws {
        for migration in allMigrations {
            self.registerMigration(migration.name) { db in
                try migration(db)
            }
        }
    }
}

private let allMigrations: [Migration] = [
    Migration1_CreateItemTable(),
]
