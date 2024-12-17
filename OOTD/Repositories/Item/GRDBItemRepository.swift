//
//  GRDBItemRepository.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/13.
//

import Foundation
import GRDB

final class GRDBItemRepository: ItemRepository {
    private let dbQueue: DatabaseQueue
    static let shared: GRDBItemRepository = .init()
    
    struct ItemDAO: Codable, FetchableRecord, PersistableRecord, Equatable, Identifiable {
        var id: String
        var name: String
        var categoryId: Int
        var tags: String
        var purchasedPrice: Int?
        var purchasedOn: Date?
        var createdAt: Date
        var updatedAt: Date
        var sourceUrl: String?
        var originalCategoryPath: String?
        var originalColor: String?
        var originalBrand: String?
        var originalSize: String?
        var originalDescription: String?

        static let databaseTableName = "items"
        
        private enum CodingKeys: String, CodingKey {
            case id
            case name
            case categoryId = "category_id"
            case tags
            case purchasedPrice = "purchased_price"
            case purchasedOn = "purchased_on"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case sourceUrl = "source_url"
            case originalCategoryPath = "original_category_path"
            case originalColor = "original_color"
            case originalBrand = "original_brand"
            case originalSize = "original_size"
            case originalDescription = "original_description"
        }
        
        init(item: Item) {
            self.id = item.id
            self.name = item.name
            self.createdAt = item.createdAt!
            self.updatedAt = item.updatedAt!
            self.categoryId = item.category.id
            self.tags = try! item.tags.toJSONString()
            self.purchasedPrice = item.purchasedPrice
            self.purchasedOn = item.purchasedOn
            self.createdAt = item.createdAt!
            self.updatedAt = item.updatedAt!
            self.sourceUrl = item.sourceUrl
            self.originalCategoryPath = try! item.originalCategoryPath?.toJSONString()
            self.originalColor = item.originalColor
            self.originalBrand = item.originalBrand
            self.originalSize = item.originalSize
            self.originalDescription = item.originalDescription
        }
        
        func toItem() -> Item {
            return Item(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                option: .init(
                    name: name,
                    category: .init(rawValue: categoryId) ?? .uncategorized,
                    tags: try! tags.toStringArray(),
                    purchasedPrice: purchasedPrice,
                    purchasedOn: purchasedOn,
                    sourceUrl: sourceUrl,
                    originalCategoryPath: try! originalCategoryPath?.toStringArray(),
                    originalColor: originalColor,
                    originalBrand: originalBrand,
                    originalSize: originalSize,
                    originalDescription: originalDescription
                )
            )
        }
    }
    
    private init() {
        let databasePath = try! Self.databasePath()
        self.dbQueue = try! DatabaseQueue(path: databasePath)
        
        try! Self.migrate(dbQueue)
    }
    
    private static func databasePath() throws -> String {
        let fileManager = FileManager.default
        let appSupportDirectory = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let databaseURL = appSupportDirectory.appendingPathComponent("db.grdb.sqlite")
        return databaseURL.path
    }
    
    private static func migrate(_ dbQueue: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()
        try migrator.registerAll()
        try migrator.migrate(dbQueue)
        logger.debug("migrated")
    }
    
    func findAll() async throws -> [Item] {
        let items = try await dbQueue.read { db in
            try ItemDAO.fetchAll(db).map { $0.toItem() }
        }
        
        logger.debug("fetched all \(items.count) items")
        
        return items
    }
    
    func save(_ items: [Item]) async throws -> [(item: Item, error: Error?)] {
        try await dbQueue.write { db in
            var results: [(item: Item, error: Error?)] = []
            
            for item in items {
                do {
                    let dao = ItemDAO(item: item)
                    try dao.upsert(db)
                    logger.debug("saved item id=\(dao.id)")
                    results.append((item: item, error: nil))
                } catch {
                    logger.warning("\(error)")
                    results.append((item: item, error: error))
                }
            }
            
            return results
        }
    }
    
    func delete(_ items: [Item]) async throws {
        try await dbQueue.write { db in
            for item in items {
                try ItemDAO.deleteOne(db, key: item.id)
                logger.debug("deleted item id=\(item.id)")
            }
        }
    }
}
