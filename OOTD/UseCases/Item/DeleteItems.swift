//
//  DeleteItems.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/27.
//

import Foundation

struct DeleteItems {
    let repository: ItemRepository

    func callAsFunction(_ items: [Item]) async throws {
        // TODO: とりあえず、DB書き込み or 画像保存の片方が失敗したときの、もう片方の rollback は後回しにしてる
        // 「DBから削除して、画像を削除できなかった」より「画像だけ削除して、DBから削除できなかった」のほうがユーザーから見えるバグなので、DB→画像の順で削除する
        try await repository.delete(items)

        for item in items {
            await doWithErrorLog {
                try await deleteImage(item)
            }
        }
    }

    private func deleteImage(_ item: Item) async throws {
        // Item.imageSource == .localPath のときだけ削除するのはダメ
        // create したばかりのアイテムをすぐ削除しようとすると imageSource = .uiImage | .url となり、
        // LocalStorage に保存した画像が削除されなくなる
        try await LocalStorage.applicationSupport.remove(at: item.imagePath)
        try await LocalStorage.applicationSupport.remove(at: item.thumbnailPath)
    }
}
