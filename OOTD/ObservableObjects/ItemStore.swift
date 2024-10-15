//
//  ItemStore.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/14.
//

import Foundation

private let logger = getLogger(#file)

class ItemStore: ObservableObject {
    var dataSource: ItemDataSource

    @Published var items: [Item] = []

    @MainActor
    init(_ dataSourceType: DataSourceType = .sample) {
        switch dataSourceType {
        case .sample:
            dataSource = SampleItemDataSource()
        case .swiftData:
            dataSource = SwiftDataItemDataSource.shared
        }
    }

    @MainActor
    func fetch() async throws {
        logger.debug("fetch items")
        items = try await dataSource.fetch()
    }

    func create(_ items: [Item]) async throws {
        let now = Date()
        let items = items.map {
            $0
                .copyWith(\.createdAt, value: now)
                .copyWith(\.updatedAt, value: now)
        }

        Task {
            try await dataSource.create(items)
        }

        await MainActor.run {
            self.items.append(contentsOf: items)
        }
    }

    func update(_ editedItems: [Item], originalItems: [Item] = []) async throws {
        // originalItems と比較して、フィールドが更新された Item のみ更新する

        let itemsToUpdate: [Item]

        if originalItems.isEmpty {
            itemsToUpdate = editedItems
        } else if editedItems.count == originalItems.count {
            itemsToUpdate = zip(originalItems, editedItems).compactMap { original, edited -> Item? in

                if original == edited {
                    return nil
                }

                logger.debug("""
                original item:
                    id: \(original.id)
                    name: \(original.name)
                    category: \(original.category.rawValue)

                edited item:
                    id: \(edited.id)
                    name: \(edited.name)
                    category: \(edited.category.rawValue)
                """)

                return edited
            }
        } else {
            logger.error("originalItems is empty and originalItems.count != editedItems.count")
            return
        }

        let now = Date()
        let updatedItems = itemsToUpdate.map {
            $0
                .copyWith(\.updatedAt, value: now)
        }

        for item in updatedItems {
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                logger.debug("update local item at index=\(index)")
                DispatchQueue.main.async {
                    self.items[index] = item
                }
            }
        }

        Task {
            try await dataSource.update(updatedItems)
        }
    }

    func filter(_ items: [Item], by filter: ItemFilter) -> [Item] {
        var newItems: [Item] = items

        if let category = filter.category {
            newItems = newItems.filter { $0.category == category }
        }

        return newItems
    }

    func delete(_ items: [Item]) async throws {
        DispatchQueue.main.async {
            self.items.removeAll { item in items.contains { item.id == $0.id } }
        }
        Task {
            try await dataSource.delete(items)
        }
    }

    func export(_ target: ItemDataSource, limit: Int? = nil) async throws {
        logger.debug("\(String(describing: Self.self)).\(#function) to \(String(describing: type(of: target)))")

        let items: [Item]
        if let limit {
            items = Array(self.items.prefix(limit))
        } else {
            items = self.items
        }

        try await target.create(items)
    }

    func import_(_ source: ItemDataSource) async throws {
        logger.debug("\(String(describing: Self.self)).\(#function) from \(String(describing: type(of: source)))")

        let items = try await source.fetch()

        var newItems: [Item] = []

        for item in items {
            let exists = self.items.contains { item_ in
                item.id == item_.id
            }

            if !exists {
                doWithErrorLog {
                    // .imageSource に uiImage を持たせようとするとメモリが足りないので、 ここで画像の読み込みと書き出しを行う
                    // TODO: ここの処理を .create に移譲すべきかも。ImageSource の localPath を applicationSupport と documents で分ければできるはず。
                    let image = try LocalStorage.documents.loadImage(from: "backup/\(item.imagePath)")
                    try LocalStorage.applicationSupport.save(image: image, to: item.imagePath)
                    let thumbnail = try image.resized(to: Item.thumbnailSize)
                    try LocalStorage.applicationSupport.save(image: thumbnail, to: item.thumbnailPath)

                    newItems.append(item)
                }
            }
        }

        guard !newItems.isEmpty else {
            throw "no items to import"
        }

        try await create(newItems)
    }
}
