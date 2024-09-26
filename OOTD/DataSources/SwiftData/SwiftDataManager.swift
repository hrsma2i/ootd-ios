//
//  SwiftDataModelContainer.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/10.
//

import Foundation
import SwiftData

class SwiftDataManager {
    let container: ModelContainer
    let context: ModelContext

    static let shared = SwiftDataManager()

    private init() {
        container = try! ModelContainer(
            for:
            ItemDTO.self,
            SwiftDataOutfitDataSource.OutfitDTO.self,
            migrationPlan: MigrationPlan.self
        )

        // background context
        // https://www.hackingwithswift.com/quick-start/swiftdata/how-to-create-a-background-context
        context = ModelContext(container)
    }
}
