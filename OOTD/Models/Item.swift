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

    // create
    init(imageSource: ImageSource, option: Option = .init()) {
        id = UUID().uuidString
        self.imageSource = imageSource
        thumbnailSource = self.imageSource

        name = option.name
        category = option.category
        purchasedPrice = option.purchasedPrice
        purchasedOn = option.purchasedOn
        // createdAt, updatedAt は ItemStore で書き込み時にセットする
        sourceUrl = option.sourceUrl
        originalCategoryPath = option.originalCategoryPath
        originalColor = option.originalColor
        originalBrand = option.originalBrand
        originalSize = option.originalSize
        originalDescription = option.originalDescription
    }

    // read
    init(id: String, createdAt: Date, updatedAt: Date, option: Option = .init()) {
        self.id = id
        imageSource = .localPath(Item.generateImagePath(id, size: Item.imageSize))
        thumbnailSource = .localPath(Item.generateImagePath(id, size: Item.thumbnailSize))

        name = option.name
        category = option.category
        purchasedPrice = option.purchasedPrice
        purchasedOn = option.purchasedOn
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        sourceUrl = option.sourceUrl
        originalCategoryPath = option.originalCategoryPath
        originalColor = option.originalColor
        originalBrand = option.originalBrand
        originalSize = option.originalSize
        originalDescription = option.originalDescription
    }

    var imagePath: String {
        Item.generateImagePath(id, size: Item.imageSize)
    }

    var thumbnailPath: String {
        Item.generateImagePath(id, size: Item.thumbnailSize)
    }

    // init 内でも使うので id は引数として受け取る
    private static func generateImagePath(_ id: String, size: CGFloat) -> String {
        return "dev/item_images_\(Int(size))/\(id).jpg"
    }

    // 画像加工時に使う
    func getUiImage() async throws -> UIImage {
        switch imageSource {
        case .uiImage(let image):
            return image
        case .url(let url):
            let image = try await downloadImage(url)
            return image
        case .localPath(let path):
            let image = try LocalStorage.loadImage(from: path)
            return image
        }
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

        guard let detail = try await generateEcItemDetail(url: sourceUrl) else {
            throw "detail page is nil"
        }

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
