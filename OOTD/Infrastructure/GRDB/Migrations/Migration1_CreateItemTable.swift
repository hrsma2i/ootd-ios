//
//  Migration1_CreateItemTable.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/17.
//

import Foundation
import GRDB

struct Migration1_CreateItemTable: Migration {
    let name = "create item table"

    func callAsFunction(_ db: Database) throws {
        try db.create(table: "items") { t in
            t.column("id", .text).notNull().primaryKey()
            t.column("name", .text).notNull()
            t.column("category_id", .integer).notNull()
            t.column("created_at", .datetime).notNull()
            t.column("updated_at", .datetime).notNull()
            t.column("tags", .text).notNull()
            t.column("purchased_price", .integer)
            t.column("purchased_on", .date)
            t.column("source_url", .text)
            t.column("original_category_path", .text)
            t.column("original_color", .text)
            t.column("original_brand", .text)
            t.column("original_size", .text)
            t.column("original_description", .text)
        }
        logger.debug("finished the migration `\(name)`")
    }
}
