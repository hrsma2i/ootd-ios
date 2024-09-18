//
//  Item.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/21.
//

import Foundation
import UIKit

private let logger = getLogger(#file)

struct Item: Hashable {
    var id: String?
    var imageSource: ImageSource
    var thumbnailSource: ImageSource
    var category: Category = .uncategorized
    var sourceUrl: String?

    static let imageSize: CGFloat = 500
    static let thumbnailSize: CGFloat = 200

    // create
    init(imageSource: ImageSource, category: Category = .uncategorized, sourceUrl: String? = nil) {
        // TODO: UUID による id の生成もここでやったほうが良さそう。ただし、ItemDetail の create / update まわりを工夫する必要がある
        self.imageSource = imageSource
        thumbnailSource = self.imageSource
        self.category = category
        self.sourceUrl = sourceUrl
    }

    // read
    init(id: String, category: Category = .uncategorized, sourceUrl: String? = nil) {
        self.id = id
        imageSource = .localPath(Item.generateImagePath(id, size: Item.imageSize))
        thumbnailSource = .localPath(Item.generateImagePath(id, size: Item.thumbnailSize))
        self.category = category
        self.sourceUrl = sourceUrl
    }

    // 返り値を String? などにしたくないので、 id == nil の場合もあるため、 id は引数で受け取ることにした。
    static func generateImagePath(_ id: String, size: CGFloat) -> String {
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
