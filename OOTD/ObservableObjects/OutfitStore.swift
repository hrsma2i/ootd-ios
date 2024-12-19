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
    let storage: FileStorage
    
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
    func fetch(itemsToJoin: [Item]) async throws {
        logger.debug("fetch outfits")
        outfits = try await GetOutfits(repository: repository, storage: storage)(itemsToJoin: itemsToJoin)
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
            targetStorage: storage,
            sourceStorage: nil
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
            targetStorage: storage,
            sourceStorage: storage
        )(editedOutfits, originalOutfits: originalOutfits)
        
        for outfit in updatedOutfits {
            if let index = outfits.firstIndex(where: { $0.id == outfit.id }) {
                logger.debug("update local outfit at index=\(index)")
                outfits[index] = outfit
            }
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
    
    func export(to target: (repository: OutfitRepository, storage: FileStorage), itemsToJoin: [Item], limit: Int? = nil) async throws {
        let results = try await MigrateOutfits(
            source: (repository: repository, storage: storage),
            target: target
        )(itemsToJoin: itemsToJoin)
    }

    func import_(from source: (repository: OutfitRepository, storage: FileStorage), itemsToJoin: [Item]) async throws {
        let results = try await MigrateOutfits(
            source: source,
            target: (repository: repository, storage: storage)
        )(itemsToJoin: itemsToJoin)

        outfits += results
            .filter { $0.error == nil }
            .map { $0.outfit }
    }
}
