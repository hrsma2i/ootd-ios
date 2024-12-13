//
//  OutfitStore.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/14.
//

import Combine
import Foundation



class OutfitStore: ObservableObject {
    private let repository: OutfitRepository
    private let storage: FileStorage

    @Published var outfits: [Outfit] = []
    @Published var searchText: String = ""
    @Published var query = OutfitQuery(
        name: "すべて",
        sort: .createdAtDescendant
    )
    @Published var displayedOutfits: [Outfit] = []
    private var cancellables = Set<AnyCancellable>()
    @Published var isWriting: Bool = false

    @MainActor
    init(_ repositoryType: RepositoryType = .sample) {
        switch repositoryType {
        case .sample:
            repository = SampleOutfitRepository()
            storage = InMemoryStorage()
        case .swiftData:
            repository = SwiftDataOutfitRepository.shared
            storage = LocalStorage.applicationSupport
        }

        // outfits または query が更新されるたびに tabs を更新
        Publishers.CombineLatest3($outfits, $searchText, $query)
            .sink { [weak self] outfits, searchText, query in
                Task {
                    try await self?.updateDisplayedOutfits(outfits: outfits, searchText: searchText, query: query)
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func updateDisplayedOutfits(outfits: [Outfit], searchText: String, query: OutfitQuery) async throws {
        // 一時的な searchText は ItemQuery として保存したくないので、別で与える
        var outfits = outfits
        let searchOutfitsByText = InMemorySearchOutfits(outfits: outfits)
        outfits = try await searchOutfitsByText(text: searchText)

        let searchOutfitsByQuery = InMemorySearchOutfits(outfits: outfits)
        outfits = try await searchOutfitsByQuery(query: query)

        displayedOutfits = outfits
    }

    @MainActor
    func fetch() async throws {
        logger.debug("fetch outfits")
        outfits = try await GetOutfits(repository: repository)()
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

        try await AddOutfits(
            repository: repository,
            storage: storage
        )(outfits)

        self.outfits.append(contentsOf: outfits)
    }

    @MainActor
    func update(_ editedOutfits: [Outfit], originalOutfits: [Outfit] = []) async throws {
        // originalOutfits と比較して、フィールドが更新された Outfit のみ更新する
        isWriting = true
        defer {
            isWriting = false
        }

        let updatedOutfits = try await EditOutfits(
            repository: repository,
            storage: storage
        )(editedOutfits, originalOutfits: originalOutfits)

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

    @MainActor
    func delete(_ outfits: [Outfit]) async throws {
        isWriting = true
        defer {
            isWriting = false
        }

        try await DeleteOutfits(
            repository: repository,
            storage: storage
        )(outfits)
        self.outfits.removeAll { outfit in outfits.contains { outfit.id == $0.id } }
    }

    func export(_ target: OutfitRepository, limit: Int? = nil) async throws {
        logger.debug("\(String(describing: Self.self)).\(#function) to \(String(describing: type(of: target)))")

        let outfits: [Outfit]
        if let limit {
            outfits = Array(self.outfits.prefix(limit))
        } else {
            outfits = self.outfits
        }

        try await target.save(outfits)
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
