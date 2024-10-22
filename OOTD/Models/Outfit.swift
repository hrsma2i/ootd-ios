//
//  Outfit.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/22.
//

import Foundation
import UIKit

private let logger = getLogger(#file)

struct Outfit: Hashable {
    let id: String

    var items: [Item]
    var itemIDs: [String]
    var imageSource: ImageSource?
    var thumbnailSource: ImageSource?
    var tags: [String]
    var createdAt: Date?
    var updatedAt: Date?

    // create
    init(items: [Item], imageSource: ImageSource? = nil, tags: [String] = []) {
        id = UUID().uuidString
        self.items = items
        itemIDs = []
        self.imageSource = imageSource
        thumbnailSource = self.imageSource
        self.tags = tags
        // createdAt, updatedAt は OutfitStore で書き込み時にセットする
    }

    // read
    // Item と異なり、imageSource が nil になることもあるため
    init(id: String, itemIds: [String], imageSource: ImageSource?, thumbnailSource: ImageSource?, tags: [String] = [], createdAt: Date, updatedAt: Date) {
        self.id = id
        itemIDs = itemIds
        items = []
        self.imageSource = imageSource
        self.thumbnailSource = thumbnailSource
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static let imageSize: CGFloat = 500
    static let thumbnailSize: CGFloat = 200

    var imagePath: String {
        return Outfit.generateImagePath(id, size: Outfit.imageSize)
    }

    var thumbnailPath: String {
        return Outfit.generateImagePath(id, size: Outfit.thumbnailSize)
    }

    // init や DataSource.read 内でも使うので id は引数として受け取る
    static func generateImagePath(_ id: String, size: CGFloat) -> String {
        return "dev/outfit_images_\(Int(size))/\(id).jpg"
    }

    func copyWith<T>(_ keyPath: WritableKeyPath<Outfit, T>, value: T) -> Outfit {
        var clone = self
        clone[keyPath: keyPath] = value
        return clone
    }
}
