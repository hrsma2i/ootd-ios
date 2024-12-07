//
//  ItemStore.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/14.
//

import Combine
import Foundation

private let logger = getLogger(#file)

class ItemStore: ObservableObject {
    var repository: ItemRepository

    @Published var items: [Item] = []
    @Published var searchText: String = ""
    @Published var queries: [ItemQuery] = []
    @Published private(set) var tabs: [Tab] = []
    private var cancellables = Set<AnyCancellable>()
    @Published var isWriting: Bool = false

    struct Tab {
        var query: ItemQuery
        var items: [Item]
    }

    @MainActor
    init(_ repositoryType: RepositoryType = .sample) {
        switch repositoryType {
        case .sample:
            repository = SampleItemRepository()
        case .swiftData:
            repository = SwiftDataItemRepository.shared
        }

        initQueries()

        // items または queries が更新されるたびに tabs を更新
        Publishers.CombineLatest3($items, $searchText, $queries)
            .sink { [weak self] items, searchText, queries in
                Task {
                    try await self?.updateTabs(items: items, searchText: searchText, queries: queries)
                }
            }
            .store(in: &cancellables)
    }

    private func initQueries() {
        let defaultQuery = ItemQuery(
            name: "すべて",
            sort: .category
        )
        queries = [defaultQuery] + Category.allCases.map { category in
            ItemQuery(
                name: category.rawValue,
                sort: .createdAtDescendant,
                filter: .init(
                    category: category
                )
            )
        }
    }

    // TODO: できれば queries のうち、更新のあった tab のみ更新したい
    @MainActor
    private func updateTabs(items: [Item], searchText: String, queries: [ItemQuery]) async throws {
        // 一時的な searchText は ItemQuery として保存したくないので、別で与える
        var items = items
        let searchItemsByText = InMemorySearchItems(items: items)
        items = try await searchItemsByText(text: searchText)

        let searchItemsByQuery = InMemorySearchItems(items: items)
        let tabs = await queries.asyncCompactMap(isParallel: false) { query -> Tab? in
            guard let items = await doWithErrorLog({
                try await searchItemsByQuery(query: query)
            }) else {
                return nil
            }

            return Tab(
                query: query,
                items: items
            )
        }

        self.tabs = tabs
    }

    @MainActor
    func fetch() async throws {
        logger.debug("fetch items")
        items = try await GetItems(repository: repository)()
    }

    @MainActor
    func create(_ items: [Item]) async throws {
        isWriting = true
        defer {
            isWriting = false
        }

        let now = Date()
        let items = items.map {
            $0
                .copyWith(\.createdAt, value: now)
                .copyWith(\.updatedAt, value: now)
                .copyWith(\.purchasedOn, value: $0.purchasedOn ?? now)
        }

        try await AddItems(repository: repository)(items)

        self.items.append(contentsOf: items)
    }

    @MainActor
    func update(_ editedItems: [Item], originalItems: [Item] = []) async throws {
        // originalItems と比較して、フィールドが更新された Item のみ更新する

        isWriting = true
        defer {
            isWriting = false
        }

        let updatedItems = try await EditItems(repository: repository)(editedItems, originalItems: originalItems)

        for item in updatedItems {
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                logger.debug("update local item at index=\(index)")
                items[index] = item
            }
        }
    }

    @MainActor
    func delete(_ items: [Item]) async throws {
        isWriting = true
        defer {
            isWriting = false
        }

        try await DeleteItems(repository: repository)(items)
        self.items.removeAll { item in items.contains { item.id == $0.id } }
    }

    func export(_ target: ItemRepository, limit: Int? = nil) async throws {
        logger.debug("\(String(describing: Self.self)).\(#function) to \(String(describing: type(of: target)))")

        let items: [Item]
        if let limit {
            items = Array(self.items.prefix(limit))
        } else {
            items = self.items
        }

        try await target.save(items)
    }

    func import_(_ source: ItemRepository) async throws {
        logger.debug("\(String(describing: Self.self)).\(#function) from \(String(describing: type(of: source)))")

        var items = try await source.findAll()

        items = items.filter { item in
            !self.items.contains { item_ in
                item.id == item_.id
            }
        }

        guard !items.isEmpty else {
            throw "no items to import"
        }

        try await create(items)
    }
}
