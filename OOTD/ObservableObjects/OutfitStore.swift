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
        let now = Date()
        let outfits = outfits.map {
            $0
                .copyWith(\.createdAt, value: now)
                .copyWith(\.updatedAt, value: now)
        }

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

        let now = Date()
        let updatedOutfits = outfitsToUpdate.map {
            $0
                .copyWith(\.updatedAt, value: now)
        }

        for outfit in updatedOutfits {
            if let index = outfits.firstIndex(where: { $0.id == outfit.id }) {
                logger.debug("update local outfit at index=\(index)")
                DispatchQueue.main.async {
                    self.outfits[index] = outfit
                }
            }
        }

        Task {
            try await dataSource.update(updatedOutfits)
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

    func filterAndSort(_ outfits: [Outfit], by condition: OutfitGridTab) -> [Outfit] {
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

        guard !outfits.isEmpty else {
            throw "no outfits to import"
        }

        try await create(outfits)
    }
}
