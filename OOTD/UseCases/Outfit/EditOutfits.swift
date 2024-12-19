//
//  EditOutfits.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/27.
//

import Foundation

struct EditOutfits {
    let repository: OutfitRepository
    let targetStorage: FileStorage
    let sourceStorage: FileStorage?

    init(repository: OutfitRepository, targetStorage: FileStorage, sourceStorage: FileStorage?) {
        self.repository = repository
        self.targetStorage = targetStorage
        self.sourceStorage = sourceStorage
    }

    struct CommandOutfit {
        let edited: Outfit
        let original: Outfit

        var isToSave: Bool {
            edited != original
        }

        var diff: String {
            """
            original outfit:
                id: \(original.id)
                items:
                - \(original.items.map(\.id).joined(separator: "\n    - "))

            edited outfit:
                id: \(edited.id)
                items:
                - \(edited.items.map(\.id).joined(separator: "\n    - "))
            """
        }
    }

    // この関数内で .updatedAt などを更新するので、更新後の [Outfit] を返す必要がある
    func callAsFunction(_ editedOutfits: [Outfit], originalOutfits: [Outfit]) async throws -> [Outfit] {
        // TODO: 以下の詰替えの作業を外側に持っていく
        if editedOutfits.count != originalOutfits.count {
            throw "originalOutfits is empty and originalOutfits.count != editedOutfits.count"
        }
        var commandOutfits: [CommandOutfit] = []
        for (edited, original) in zip(editedOutfits, originalOutfits) {
            commandOutfits.append(.init(edited: edited, original: original))
        }

        // TODO: とりあえず、DB書き込み or 画像保存の片方が失敗したときの、もう片方の rollback は後回しにしてる
        // 「画像だけ保存して、DBに書き込めなかった」より「DBから書き込めてて、画像を保存できなかった」ほうがユーザーにとって深刻なバグなので、画像→DBの順で保存する

        commandOutfits = commandOutfits
            .filter { $0.isToSave }

        commandOutfits = await saveImages(commandOutfits)

        let now = Date()
        let outfits: [Outfit] = commandOutfits.map {
            $0.edited.copyWith(\.updatedAt, value: now)
        }

        try await repository.save(outfits)

        for outfit in commandOutfits {
            if outfit.isToSave {
                logger.debug("\(outfit.diff)")
            }
        }

        return outfits
    }

    private func saveImages(_ outfits: [CommandOutfit]) async -> [CommandOutfit] {
        let saveOutfitImage = SaveOutfitImage(target: targetStorage, source: sourceStorage)

        var successOutfits: [CommandOutfit] = []
        for outfit in outfits {
            await safeDo {
                try await saveOutfitImage(outfit.edited)
                successOutfits.append(outfit)
            }
        }

        return successOutfits
    }
}
