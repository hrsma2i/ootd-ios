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
    var id: String?

    var image: UIImage?
    var imageURL: String?
    var thumbnailURL: String?
    var items: [Item] = []
    var itemIDs: [String] = []

    static let imageSize: CGFloat = 500
    static let thumbnailSize: CGFloat = 200

    var imagePath: String? {
        guard let id else { return nil }

        return "dev/outfit_images_\(Int(Item.imageSize))/\(id).jpg"
    }

    var thumbnailPath: String? {
        guard let id else { return nil }

        return "dev/outfit_images_\(Int(Item.thumbnailSize))/\(id).jpg"
    }

    func copyWith<T>(_ keyPath: WritableKeyPath<Outfit, T>, value: T) -> Outfit {
        var clone = self
        clone[keyPath: keyPath] = value
        return clone
    }
}

let sampleOutfits = [
    Outfit(
        id: "outfit-0",
        items: [
            "thurmont_glasses",
            "gu_suede_touch_jacket_cb_camel",
            "hardrock_T_shirts",
            "black_cocoon_denim",
            "Dr_Martens_3hole",

        ].compactMap { name in
            sampleItems.filter {
                guard case let .url(url) = $0.imageSource else { return false }
                return url.contains(name)
            }.first
        }
    ),
    Outfit(
        id: "outfit-1",
        items: [
            "wellington_glasses",
            "purple_cap",
            "stripe_cream_shirts",
            "black_cocoon_denim",
            "adadias_samba_naby",
        ].compactMap { name in
            sampleItems.filter {
                guard case let .url(url) = $0.imageSource else { return false }
                return url.contains(name)
            }.first
        }
    ),
    Outfit(
        id: "outfit-2",
        imageURL: "https://images.wear2.jp/coordinate/rliwyvYY/0r5BWoTz/1679204559_500.jpg",
        thumbnailURL: "https://images.wear2.jp/coordinate/rliwyvYY/0r5BWoTz/1679204559_200.jpg",
        items: [
            "white_ma1",
            "3d_knit",
            "black_leather_pants",
            "clarks_black_wallabee_boots",
        ].compactMap { name in
            sampleItems.filter {
                guard case let .url(url) = $0.imageSource else { return false }
                return url.contains(name)
            }.first
        }
    ),
    Outfit(
        id: "outfit-3",
        imageURL: "https://images.wear2.jp/coordinate/rliwyvYY/G9xK97Yi/1682324037_500.jpg",
        thumbnailURL: "https://images.wear2.jp/coordinate/rliwyvYY/G9xK97Yi/1682324037_200.jpg"
    ),
]
