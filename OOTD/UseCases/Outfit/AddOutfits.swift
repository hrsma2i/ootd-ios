//
//  AddOutfits.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/27.
//

import Foundation

struct AddOutfits {
    let repository: OutfitRepository
    let storage: FileStorage

    func callAsFunction(_ outfits: [Outfit]) async throws {
        // TODO: とりあえず、DB書き込み or 画像保存の片方が失敗したときの、もう片方の rollback は後回しにしてる
        // 「画像だけ保存して、DBに書き込めなかった」より「DBから書き込めてて、画像を保存できなかった」ほうがユーザーにとって深刻なバグなので、画像→DBの順で保存する
        let saveImageSuccessOutfits = await saveImages(outfits)

        try await repository.save(saveImageSuccessOutfits)
    }

    private func saveImages(_ outfits: [Outfit]) async -> [Outfit] {
        let saveOutfitImage = SaveOutfitImage(storage: storage)

        var successOutfits: [Outfit] = []
        for outfit in outfits {
            await doWithErrorLog {
                try await saveOutfitImage(outfit)
                successOutfits.append(outfit)
            }
        }

        return successOutfits
    }
}
