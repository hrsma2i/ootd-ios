//
//  EditItems.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/27.
//

import Foundation

struct EditItems {
    let repository: ItemRepository
    let targetStorage: FileStorage
    let sourceStorage: FileStorage?
    
    init(repository: ItemRepository, targetStorage: FileStorage, sourceStorage: FileStorage?) {
        self.repository = repository
        self.targetStorage = targetStorage
        self.sourceStorage = sourceStorage
    }
    
    struct CommandItem {
        let edited: Item
        let original: Item
        let isImageEdited: Bool
        
        var isToSave: Bool {
            // UIImage は異なっても等しいとみなされてしまうので、画像は別途判定
            edited != original || isImageEdited
        }
    }
    
    // この関数内で .updatedAt などを更新するので、更新後の [Item] を返す必要がある
    func callAsFunction(_ items: [EditItems.CommandItem]) async throws -> [(item: EditItems.CommandItem, error: Error?)] {
        // AddItems と異なり、画像保存とリポジトリへの書き込みは独立して行える
        let saveResults = await saveToRepository(items)
        let saveImageResults = await saveImages(saveResults)

        await rollbackSaveForSaveImageFailures(
            saveImageResults: saveImageResults,
            saveResults: saveResults
        )
        
        for result in saveImageResults {
            let original = result.item.original
            let edited = result.item.edited
            if let error = result.error {
                logger.warning("failed to edit item id=\(edited.id) because \(error)")
            } else {
                logger.debug("""
                original item:
                    id: \(original.id)
                    name: \(original.name)
                    category: \(original.category.displayName)
                
                edited item:
                    id: \(edited.id)
                    name: \(edited.name)
                    category: \(edited.category.displayName)
                """)
            }
        }
        
        return saveImageResults
    }
    
    private func saveToRepository(_ items: [EditItems.CommandItem]) async -> [(item: EditItems.CommandItem, error: Error?)] {
        var itemsToSave = items
            .filter { $0.isToSave }
            .map { $0.edited }
        
        let now = Date()
        itemsToSave = itemsToSave.map {
            $0
                .copyWith(\.updatedAt, value: now)
        }
        
        let results: [(item: Item, error: Error?)]
        // TODO: 以下のエラーハンドリングを、ItemRepository.save の方に移行して throws をやめれば楽
        do {
            results = try await repository.save(itemsToSave)
        } catch {
            results = itemsToSave.map { item in
                (item: item, error: error)
            }
        }
        
        let allResults: [(item: EditItems.CommandItem, error: Error?)] = items.map { item in
            guard let result = results.first(where: { $0.item.id == item.edited.id }) else {
                // 未編集の場合、そのまま返す
                return (item: item, error: nil)
            }
            
            // 編集されてる場合、DB書き込みのエラーを添えて返す
            return (item: item, error: result.error)
        }
        
        return allResults
    }

    private func saveImages(_ saveResults: [(item: EditItems.CommandItem, error: Error?)]) async -> [(item: EditItems.CommandItem, error: Error?)] {
        let saveImage = SaveItemImage(target: targetStorage, source: sourceStorage)
        let results: [(item: EditItems.CommandItem, error: Error?)] = await saveResults.asyncMap(isParallel: false) { saveResult in
            let item = saveResult.item
            if saveResult.error != nil || !item.isImageEdited {
                return saveResult
            }
            
            do {
                try await saveImage(saveResult.item.edited)
                return (item: item, error: nil)
            } catch {
                return (item: item, error: error)
            }
        }
        return results
    }
    
    private func rollbackSaveForSaveImageFailures(
        saveImageResults: [(item: EditItems.CommandItem, error: Error?)],
        saveResults: [(item: EditItems.CommandItem, error: Error?)]
    ) async {
        let onlySaveImageFailures = saveImageResults
            .filter { result in
                // DB書き込みにも失敗した場合はロールバック不要
                if
                    let saveResult = saveResults.first(where: { $0.item.edited.id == result.item.edited.id }),
                    saveResult.error != nil
                {
                    return true
                }
                
                return result.error != nil
            }
        
        for result in onlySaveImageFailures {
            logger.warning("rollback update item id=\(result.item.edited.id) bacause \(result.error)")
        }
        
        // 変更前のアイテムをDBに書き戻す
        _ = await safeDo {
            try await repository.save(onlySaveImageFailures.map(\.item.original))
        }
    }
}
