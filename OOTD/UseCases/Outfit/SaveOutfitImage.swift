//
//  SaveOutfitImage.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/12.
//

import Foundation

struct SaveOutfitImage {
    let storage: FileStorage

    func callAsFunction(_ outfit: Outfit) async throws {
        guard let image = try await outfit.imageSource?.getUiImage() else {
            // 画像がない場合は特に何もしない
            // Item と異なり、 imageSource = nil はよくあることなので、 Outfit 自体の保存は中断されないようにする
            return
        }

        try await storage.saveImage(image: image.resized(to: Outfit.imageSize), to: outfit.imagePath)
        try await storage.saveImage(image: image.resized(to: Outfit.thumbnailSize), to: outfit.thumbnailPath)
    }
}
