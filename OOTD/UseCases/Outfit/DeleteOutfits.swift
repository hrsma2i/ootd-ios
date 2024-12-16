//
//  DeleteOutfits.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/27.
//

import Foundation

struct DeleteOutfits {
    let repository: OutfitRepository
    let storage: FileStorage

    func callAsFunction(_ outfits: [Outfit]) async throws {
        // TODO: とりあえず、DB書き込み or 画像保存の片方が失敗したときの、もう片方の rollback は後回しにしてる
        // 「DBから削除して、画像を削除できなかった」より「画像だけ削除して、DBから削除できなかった」のほうがユーザーから見えるバグなので、DB→画像の順で削除する
        try await repository.delete(outfits)

        for outfit in outfits {
            await safeDo {
                try await deleteImage(outfit)
            }
        }
    }

    private func deleteImage(_ outfit: Outfit) async throws {
        if outfit.imageSource == nil {
            return
        }
        // Outfit.imageSource == .localPath のときだけ削除するのはダメ
        // create したばかりのアイテムをすぐ削除しようとすると imageSource = .uiImage | .url となり、
        // LocalStorage に保存した画像が削除されなくなる
        try await storage.remove(at: outfit.imagePath)
        try await storage.remove(at: outfit.thumbnailPath)
    }
}
