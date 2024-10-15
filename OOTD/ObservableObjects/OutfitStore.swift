//
//  OutfitStore.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/14.
//

import Foundation

private let logger = getLogger(#file)

class OutfitStore: ObservableObject {
    @Published var outfits: [Outfit] = []
    private let dataSource: OutfitDataSource

    @MainActor
    init(_ dataSourceType: DataSourceType = .sample) {
        switch dataSourceType {
        case .sample:
            dataSource = SampleOutfitDataSource()
        case .swiftData:
            dataSource = SwiftDataOutfitDataSource.shared
        }
    }

    @MainActor
    func fetch() async throws {
        logger.debug("fetch outfits")
        outfits = try await dataSource.fetch()
    }

    func create(_ outfits: [Outfit]) async throws {
        Task {
            try await dataSource.create(outfits)
        }

        await MainActor.run {
            self.outfits.append(contentsOf: outfits)
        }
    }

    func update(_ editedOutfits: [Outfit], originalOutfits: [Outfit] = []) async throws {
        // originalOutfits と比較して、フィールドが更新された Outfit のみ更新する

        let outfitsToUpdate: [Outfit]

        if originalOutfits.isEmpty {
            outfitsToUpdate = editedOutfits
        } else if editedOutfits.count == originalOutfits.count {
            outfitsToUpdate = zip(originalOutfits, editedOutfits).compactMap { original, edited -> Outfit? in

                if original == edited {
                    return nil
                }

                logger.debug("""
                original outfit:
                    id: \(original.id)
                    items:
                    - \(original.items.map(\.id).joined(separator: "\n    - "))

                edited outfit:
                    id: \(edited.id)
                    items:
                    - \(edited.items.map(\.id).joined(separator: "\n    - "))
                """)

                return edited
            }
        } else {
            logger.error("originalOutfits is empty and originalOutfits.count != editedOutfits.count")
            return
        }

        for outfit in outfitsToUpdate {
            if let index = outfits.firstIndex(where: { $0.id == outfit.id }) {
                logger.debug("update local outfit at index=\(index)")
                DispatchQueue.main.async {
                    self.outfits[index] = outfit
                }
            }
        }

        Task {
            try await dataSource.update(outfitsToUpdate)
        }
    }

    func joinItems(_ items: [Item]) {
        logger.debug("join items")
        outfits = outfits.map { outfit in
            if !outfit.items.isEmpty {
                return outfit
            }

            return outfit.copyWith(\.items, value: outfit.itemIDs.compactMap { itemID in
                items.first { $0.id == itemID }
            })
        }
    }

    func getOutfits(using items: [Item]) -> [Outfit] {
        outfits.filter { outfit in
            outfit.items.contains { item in items.contains { $0.id == item.id }}
        }
    }

    func delete(_ outfits: [Outfit]) async throws {
        DispatchQueue.main.async {
            self.outfits.removeAll { outfit in outfits.contains { outfit.id == $0.id } }
        }
        Task {
            try await dataSource.delete(outfits)
        }
    }

    func filterAndSort(_ outfits: [Outfit], by condition: OutfitCondition) -> [Outfit] {
        var newOutfits: [Outfit] = outfits

        newOutfits = newOutfits.filter { outfit in condition.filter.items.allSatisfy { outfit.items.contains($0) } }

        return newOutfits
    }

    func export(_ target: OutfitDataSource, limit: Int? = nil) async throws {
        logger.debug("\(String(describing: Self.self)).\(#function) to \(String(describing: type(of: target)))")

        let outfits: [Outfit]
        if let limit {
            outfits = Array(self.outfits.prefix(limit))
        } else {
            outfits = self.outfits
        }

        try await target.create(outfits)
    }

    func import_(_ source: OutfitDataSource) async throws {
        logger.debug("\(String(describing: Self.self)).\(#function) from \(String(describing: type(of: source)))")

        var outfits = try await source.fetch()

        outfits = outfits.filter { outfit in
            !self.outfits.contains { outfit_ in
                outfit.id == outfit_.id
            }
        }

        outfits = outfits.map { outfit in
            do {
                // .mageSource に uiImage を持たせようとするとメモリが足りないので、 ここで画像の読み込みと書き出しを行う
                // TODO: ここの処理を .create に移譲すべきかも。ImageSource の localPath を applicationSupport と documents で分ければできるはず。
                let image = try LocalStorage.documents.loadImage(from: "backup/\(outfit.imagePath)")
                try LocalStorage.applicationSupport.save(image: image, to: outfit.imagePath)
                let thumbnail = try image.resized(to: Item.thumbnailSize)
                try LocalStorage.applicationSupport.save(image: thumbnail, to: outfit.thumbnailPath)

                return outfit
                    .copyWith(\.imageSource, value: .localPath(outfit.imagePath))
                    .copyWith(\.thumbnailSource, value: .localPath(outfit.thumbnailPath))
            } catch {
                logger.debug("\(error)")
                return outfit
            }
        }

        guard !outfits.isEmpty else {
            throw "no outfits to import"
        }

        try await create(outfits)
    }
}
