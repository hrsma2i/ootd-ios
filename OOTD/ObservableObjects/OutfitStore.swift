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
    private let repository: OutfitRepository
    @Published var isWriting: Bool = false

    @MainActor
    init(_ repositoryType: RepositoryType = .sample) {
        switch repositoryType {
        case .sample:
            repository = SampleOutfitRepository()
        case .swiftData:
            repository = SwiftDataOutfitRepository.shared
        }
    }

    @MainActor
    func fetch() async throws {
        logger.debug("fetch outfits")
        outfits = try await repository.findAll()
    }

    @MainActor
    func create(_ outfits: [Outfit]) async throws {
        isWriting = true
        defer {
            isWriting = false
        }

        let now = Date()
        let outfits = outfits.map {
            $0
                .copyWith(\.createdAt, value: now)
                .copyWith(\.updatedAt, value: now)
        }

        try await repository.create(outfits)

        self.outfits.append(contentsOf: outfits)
    }

    @MainActor
    func update(_ editedOutfits: [Outfit], originalOutfits: [Outfit] = []) async throws {
        // originalOutfits と比較して、フィールドが更新された Outfit のみ更新する
        isWriting = true
        defer {
            isWriting = false
        }

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
            throw "originalOutfits is empty and originalOutfits.count != editedOutfits.count"
        }

        let now = Date()
        let updatedOutfits = outfitsToUpdate.map {
            $0
                .copyWith(\.updatedAt, value: now)
        }

        try await repository.update(updatedOutfits)

        for outfit in updatedOutfits {
            if let index = outfits.firstIndex(where: { $0.id == outfit.id }) {
                logger.debug("update local outfit at index=\(index)")
                outfits[index] = outfit
            }
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

    @MainActor
    func delete(_ outfits: [Outfit]) async throws {
        isWriting = true
        defer {
            isWriting = false
        }

        try await repository.delete(outfits)
        self.outfits.removeAll { outfit in outfits.contains { outfit.id == $0.id } }
    }

    func filterAndSort(_ outfits: [Outfit], by condition: OutfitGridTab) -> [Outfit] {
        var newOutfits: [Outfit] = outfits

        newOutfits = newOutfits.filter { outfit in condition.filter.items.allSatisfy { outfit.items.contains($0) } }

        return newOutfits
    }

    func export(_ target: OutfitRepository, limit: Int? = nil) async throws {
        logger.debug("\(String(describing: Self.self)).\(#function) to \(String(describing: type(of: target)))")

        let outfits: [Outfit]
        if let limit {
            outfits = Array(self.outfits.prefix(limit))
        } else {
            outfits = self.outfits
        }

        try await target.create(outfits)
    }

    func import_(_ source: OutfitRepository) async throws {
        logger.debug("\(String(describing: Self.self)).\(#function) from \(String(describing: type(of: source)))")

        var outfits = try await source.findAll()

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
