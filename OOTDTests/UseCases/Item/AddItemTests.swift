//
//  AddItemTests.swift
//  OOTDTests
//
//  Created by Hiroshi Matsui on 2024/08/26.
//

@testable import OOTD_Debug
import XCTest

final class AddItemTests: XCTestCase {
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

        let repository = InMemoryItemRepository(items: [])
        let storage = MockStorage()
        let addItems = AddItems(
            repository: repository,
            targetStorage: storage,
            sourceStorage: nil
        )

        let itemSuccess = sampleItems[0]
        let itemFailure = Item(
            id: "failure",
            createdAt: Date(),
            updatedAt: Date()
        )

        let results = try await addItems([
            itemSuccess,
            itemFailure
        ])

        XCTAssertNil(results[0].error)
        XCTAssertNotNil(results[1].error)

        // 画像保存に失敗した方は rollback され、画像保存に成功したもののみ保存されているか
        let allItems = try await repository.findAll()
        XCTAssertEqual(allItems.count, 1)
        let itemOnlySaved = allItems.first!
        XCTAssertEqual(itemOnlySaved.id, itemSuccess.id)
    }
}
