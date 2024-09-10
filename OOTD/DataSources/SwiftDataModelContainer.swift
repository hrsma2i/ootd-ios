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

    @MainActor
    static let shared = SwiftDataManager()

    @MainActor
    private init() {
        container = try! ModelContainer(for:
            SwiftDataItemDataSource.ItemDTO.self,
            SwiftDataOutfitDataSource.OutfitDTO.self)

        context = container.mainContext
    }
}
