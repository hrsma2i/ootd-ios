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
    var sourceUrl: String?
    var createdAt: Date?
    var updatedAt: Date?

    static let imageSize: CGFloat = 500
    static let thumbnailSize: CGFloat = 200

    struct Option {
        var name: String = ""
        var category: Category = .uncategorized
        var sourceUrl: String? = nil
    }

    // create
    init(imageSource: ImageSource, option: Option = .init()) {
        id = UUID().uuidString
        self.imageSource = imageSource
        thumbnailSource = self.imageSource

        name = option.name
        category = option.category
        sourceUrl = option.sourceUrl
        // createdAt, updatedAt は ItemStore で書き込み時にセットする
    }

    // read
    init(id: String, createdAt: Date, updatedAt: Date, option: Option = .init()) {
        self.id = id
        imageSource = .localPath(Item.generateImagePath(id, size: Item.imageSize))
        thumbnailSource = .localPath(Item.generateImagePath(id, size: Item.thumbnailSize))

        name = option.name
        category = option.category
        sourceUrl = option.sourceUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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
}
