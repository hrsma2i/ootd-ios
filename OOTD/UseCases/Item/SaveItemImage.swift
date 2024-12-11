//
//  SaveItemImage.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/09.
//

import Foundation

struct SaveItemImage {
    let storage: FileStorage

    func callAsFunction(_ item: Item) async throws {
        let image = try await item.imageSource.getUiImage()

        try await storage.saveImage(image: image.resized(to: Item.imageSize), to: item.imagePath)
        try await storage.saveImage(image: image.resized(to: Item.thumbnailSize), to: item.thumbnailPath)
    }
}
