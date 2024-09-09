//
//  Item.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/21.
//

import Foundation
import UIKit

private let logger = getLogger(#file)

struct Item: Hashable, Encodable {
    var id: String?

    var image: UIImage?
    var imageURL: String?
    var thumbnailURL: String?
    var resizedImageURL: String?
    var category: Category = .uncategorized
    var sourceUrl: String?

    static let imageSize: CGFloat = 500
    static let thumbnailSize: CGFloat = 200

    var imagePath: String? {
        guard let id else { return nil }

        return "dev/item_images_\(Int(Item.imageSize))/\(id).jpg"
    }

    var thumbnailPath: String? {
        guard let id else { return nil }

        return "dev/item_images_\(Int(Item.thumbnailSize))/\(id).jpg"
    }

    func copyWith<T>(_ keyPath: WritableKeyPath<Item, T>, value: T) -> Item {
        var clone = self
        clone[keyPath: keyPath] = value
        return clone
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAimportUrlt
        case updatedAt
        case imageURL
        case category
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // TODO: 特別な処理のいらないフィールドは自動化したい
        try container.encode(id, forKey: .id)
        try container.encode(category, forKey: .category)
    }
}

extension Item: Decodable {
    init(from decoder: Decoder) throws {
        // TODO: 自動化難しそうだけどやりたい
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        // そのままデフォルト値を設定してもデコード時にエラーになるだけなので、わざわざ init(from decoder) を定義する必要がある
        // https://sylvainchan.medium.com/swift-5-codable-with-default-value-519996b90c9f
        category = try container.decodeIfPresent(Category.self, forKey: .category) ?? .uncategorized
    }
}
