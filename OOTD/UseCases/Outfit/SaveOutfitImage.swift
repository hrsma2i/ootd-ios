//
//  SaveOutfitImage.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/12.
//

import Foundation

struct SaveOutfitImage {
    let target: FileStorage
    let source: FileStorage?

    init(target: FileStorage, source: FileStorage?) {
        self.target = target
        self.source = source
    }

    func callAsFunction(_ outfit: Outfit) async throws {
        guard let image = try await outfit.imageSource?.getUiImage(storage: source) else {
            // 画像がない場合は特に何もしない
            // Item と異なり、 imageSource = nil はよくあることなので、 Outfit 自体の保存は中断されないようにする
            return
        }

        try await target.saveImage(image: image.resized(to: Outfit.imageSize), to: outfit.imagePath)
        try await target.saveImage(image: image.resized(to: Outfit.thumbnailSize), to: outfit.thumbnailPath)
    }
}
