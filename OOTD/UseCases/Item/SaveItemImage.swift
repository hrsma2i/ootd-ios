//
//  SaveItemImage.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/09.
//

import Foundation

struct SaveItemImage {
    let target: FileStorage
    let source: FileStorage?

    init(target: FileStorage, source: FileStorage?) {
        self.target = target
        self.source = source
    }

    func callAsFunction(_ item: Item) async throws {
        let image = try await item.imageSource.getUiImage(storage: source)

        try await target.saveImage(image: image.resized(to: Item.imageSize), to: item.imagePath)
        try await target.saveImage(image: image.resized(to: Item.thumbnailSize), to: item.thumbnailPath)
    }
}
