//
//  Item.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/21.
//

import Foundation
import UIKit

private let logger = getLogger(#file)

struct Item: Hashable, Identifiable {
    let id: String
    var imageSource: ImageSource
    var thumbnailSource: ImageSource
    var name: String
    var category: Category = .uncategorized
    var purchasedPrice: Int?
    var purchasedOn: Date?
    var createdAt: Date?
    var updatedAt: Date?
    var sourceUrl: String?
    // original* は web からインポートした際の無加工の情報
    var originalCategoryPath: [String]?
    var originalColor: String?
    var originalBrand: String?
    var originalSize: String?
    var originalDescription: String?

    static let imageSize: CGFloat = 500
    static let thumbnailSize: CGFloat = 200

    struct Option {
        var name: String = ""
        var category: Category = .uncategorized
        var purchasedPrice: Int?
        var purchasedOn: Date?
        var sourceUrl: String? = nil
        var originalCategoryPath: [String]?
        var originalColor: String?
        var originalBrand: String?
        var originalSize: String?
        var originalDescription: String?
    }

    private init(id: String, imageSource: ImageSource, thumbnailSource: ImageSource, option: Option, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.imageSource = imageSource
        self.thumbnailSource = imageSource
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.name = option.name
        self.category = option.category
        self.purchasedPrice = option.purchasedPrice
        self.purchasedOn = option.purchasedOn
        self.sourceUrl = option.sourceUrl
        self.originalCategoryPath = option.originalCategoryPath
        self.originalColor = option.originalColor
        self.originalBrand = option.originalBrand
        self.originalSize = option.originalSize
        self.originalDescription = option.originalDescription
    }

    // create
    init(imageSource: ImageSource, option: Option = .init()) {
        // createdAt, updatedAt は ItemStore で書き込み時にセットする
        self.init(
            id: UUID().uuidString,
            imageSource: imageSource,
            thumbnailSource: imageSource,
            option: option
        )
    }

    // read
    init(id: String, createdAt: Date, updatedAt: Date, option: Option = .init()) {
        self.init(
            id: id,
            imageSource: .applicatinoSupport(Item.generateImagePath(id, size: Item.imageSize)),
            thumbnailSource: .applicatinoSupport(Item.generateImagePath(id, size: Item.thumbnailSize)),
            option: option,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    var imagePath: String {
        Item.generateImagePath(id, size: Item.imageSize)
    }

    var thumbnailPath: String {
        Item.generateImagePath(id, size: Item.thumbnailSize)
    }

    // init 内でも使うので id は引数として受け取る
    static func generateImagePath(_ id: String, size: CGFloat) -> String {
        return "dev/item_images_\(Int(size))/\(id).jpg"
    }

    func copyWith<T>(_ keyPath: WritableKeyPath<Item, T>, value: T) -> Item {
        var clone = self
        clone[keyPath: keyPath] = value
        return clone
    }

    func copyWithPropertiesFromSourceUrl() async throws -> Item {
        guard let sourceUrl else {
            throw "Item.sourceUrl is nil"
        }

        let detail = try await generateEcItemDetail(url: sourceUrl)

        let redirectedUrl = detail.url
        let price = try? detail.price()
        let originalCategoryPath = try? detail.categoryPath()
        let originalDescription = try? detail.description()

        let updatedItem = copyWith(\.sourceUrl, value: redirectedUrl)
            .copyWith(\.originalCategoryPath, value: originalCategoryPath ?? self.originalCategoryPath)
            .copyWith(\.originalDescription, value: originalDescription ?? self.originalDescription)
            .copyWith(\.purchasedPrice, value: price ?? purchasedPrice)

        return updatedItem
    }
}
