//
//  EditItemsTests.swift
//  OOTDTests
//
//  Created by Hiroshi Matsui on 2024/12/10.
//

import Foundation
@testable import OOTD_Debug
import XCTest

final class EditItemsTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testImageSaveFailure() async throws {
        class MockStorage: InMemoryStorage {
            override func save(data: Data, to: String) async throws {
                if to.contains("failure") {
                    throw "failed to save image"
                }
            }
        }

        let storage = MockStorage()

        let itemSuccess = sampleItems[0]
        let itemFailure = Item(
            id: "failure",
            createdAt: Date(),
            updatedAt: Date()
        )

        let repository = InMemoryItemRepository(items: [
            itemSuccess,
            itemFailure,
        ])
        let editItems = EditItems(
            repository: repository,
            storage: storage
        )

        let itemSuccessEdited = itemSuccess.copyWith(\.category, value: .bottoms)
        let itemFailureEdited = itemFailure.copyWith(\.category, value: .bottoms)

        let results = try await editItems([
            .init(edited: itemSuccessEdited, original: itemSuccess, isImageEdited: true),
            .init(edited: itemFailureEdited, original: itemFailure, isImageEdited: true),
        ])

        XCTAssertNil(results[0].error)
        XCTAssertNotNil(results[1].error)

        let allItems = try await repository.findAll()
        // 画像保存に成功した方は、他のプロパティも更新されてるか
        XCTAssertEqual(allItems[0].category, .bottoms)
        // 画像保存に失敗した方は rollback され、編集前に戻っているか
        XCTAssertEqual(allItems[1].category, .uncategorized)
    }
}
