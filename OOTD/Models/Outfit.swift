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

    // create
    init(items: [Item], imageSource: ImageSource? = nil) {
        id = UUID().uuidString
        self.items = items
        itemIDs = []
        self.imageSource = imageSource
        thumbnailSource = self.imageSource
    }

    // read
    // Item と異なり、imageSource が nil になることもあるため
    init(id: String, itemIds: [String], imageSource: ImageSource?, thumbnailSource: ImageSource?) {
        self.id = id
        itemIDs = itemIds
        items = []
        self.imageSource = imageSource
        self.thumbnailSource = thumbnailSource
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

    // 画像加工時に使う
    func getUiImage() async throws -> UIImage {
        switch imageSource {
        case let .uiImage(image):
            return image
        case let .url(url):
            let image = try await downloadImage(url)
            return image
        case let .localPath(path):
            let image = try LocalStorage.loadImage(from: path)
            return image
        default:
            throw "Outfit.imageSource is nil"
        }
    }

    func copyWith<T>(_ keyPath: WritableKeyPath<Outfit, T>, value: T) -> Outfit {
        var clone = self
        clone[keyPath: keyPath] = value
        return clone
    }
}

let sampleOutfits = [
    Outfit(
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
        },
        imageSource: .url("https://images.wear2.jp/coordinate/rliwyvYY/0r5BWoTz/1679204559_500.jpg")
    ),
    Outfit(
        items: [],
        imageSource: .url("https://images.wear2.jp/coordinate/rliwyvYY/G9xK97Yi/1682324037_500.jpg")
    ),
]
