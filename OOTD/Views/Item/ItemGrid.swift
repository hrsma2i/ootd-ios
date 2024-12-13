//
//  ItemGrid.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/20.
//

import SwiftUI

private let logger = CustomLogger(#file)

struct ItemGrid: HashableView {
    init(isOnlySelectable: Bool = false, numColumns: Int = 3, selected: [Item] = [], onSelected: @escaping ([Item]) -> Void = { _ in }) {
        self.isOnlySelectable = isOnlySelectable
        self.numColumns = numColumns
        self.selected = selected
        // アイテム選択画面専用（isOnlySelectble = true） のときは、 選択モードから入る
        self.isSelectable = isOnlySelectable
        self.onSelected = onSelected
    }

    @EnvironmentObject var itemStore: ItemStore
    @EnvironmentObject var outfitStore: OutfitStore
    @EnvironmentObject var navigation: NavigationManager
    @EnvironmentObject var snackbarStore: SnackbarStore

    // MARK: - optional

    var isOnlySelectable: Bool
    var numColumns: Int
    @State var selected: [Item]
    var onSelected: ([Item]) -> Void

    // MARK: - private

    @State private var isSelectable: Bool
    @State private var isAlertPresented = false

    private enum ActiveSheet: Identifiable {
        case itemDeleteConfirmOutfits(outfits: [Outfit])
        case imagePicker
        case addOptions
        case selectSort

        var id: String {
            let mirror = Mirror(reflecting: self)
            return mirror.children.first?.label ?? "unknown"
        }
    }

    @State private var activeSheet: ActiveSheet?
    @State private var activeTabIndex: Int = 0

    var activeTab: ItemStore.Tab? {
        guard itemStore.tabs.indices.contains(activeTabIndex) else {
            return nil
        }
        return itemStore.tabs[activeTabIndex]
    }

    var sortButton: some View {
        return footerButton(
            text: activeTab?.query.sort.rawValue ?? "並べ替え",
            systemName: "arrow.up.arrow.down"
        ) {
            activeSheet = .selectSort
        }
    }

    var selectButton: some View {
        footerButton(
            text: "選択",
            systemName: "checkmark.square.fill"
        ) {
            isSelectable = true
        }
    }

    var cancelButton: some View {
        footerButton(
            text: "戻る",
            systemName: "arrow.uturn.left"
        ) {
            isSelectable = false
            selected = []
        }
    }

    var addButton: some View {
        footerButton(
            text: "追加",
            systemName: "plus"
        ) {
            activeSheet = .addOptions
        }
    }

    var editButton: some View {
        footerButton(
            text: "一括編集",
            systemName: "pencil"
        ) {
            navigation.path.append(ItemDetail(
                items: selected,
                mode: .update
            ))

            isSelectable = false
            selected = []
        }
    }

    var deleteButton: some View {
        footerButton(
            text: "一括削除",
            systemName: "trash.fill",
            color: .softRed
        ) {
            Task {
                do {
                    let outfits = try await InMemorySearchOutfits(outfits: outfitStore.outfits)(usingAny: selected)

                    if outfits.isEmpty {
                        isAlertPresented = true
                    } else {
                        activeSheet = .itemDeleteConfirmOutfits(outfits: outfits)
                    }
                } catch {
                    logger.critical("\(error)")
                }
            }
        }
    }

    var decideButton: some View {
        footerButton(
            text: "決定",
            systemName: "checkmark"
        ) {
            onSelected(selected)
        }
    }

    func footerButton(text: String, systemName: String, color: Color = .white, action: @escaping () -> Void = {}) -> some View {
        IconButton(
            text: text,
            systemName: systemName,
            color: color,
            action: action
        )
        .frame(width: 60)
    }

    var innerFooter: some View {
        HStack {
            Spacer()

            HStack(spacing: 0) {
                if !isOnlySelectable, isSelectable, !selected.isEmpty {
                    deleteButton
                    editButton
                }

                if isOnlySelectable {
                    decideButton
                } else {
                    if isSelectable {
                        cancelButton
                    } else {
                        addButton
                        selectButton
                    }
                }

                sortButton
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .foregroundColor(.accent)
                    .shadow(radius: 3)
            }
            .padding(.trailing, 10)
        }
    }

    var bottomBar: some View {
        SearchBar(text: $itemStore.searchText, placeholder: "検索")
            .padding(7)
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke()
                    .foregroundColor(.init(gray: 0.8))
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 10)
    }

    private func onTapItem_(_ item: Item) {
        if isSelectable {
            if selected.contains(item) {
                selected.removeAll { $0 == item }
            } else {
                selected.append(item)
            }
        } else {
            navigation.path.append(
                ItemDetail(
                    items: [item],
                    mode: .update
                )
            )
        }
    }

    private func itemCard(_ item: Item) -> some View {
        Button(action: { onTapItem_(item) }) {
            ZStack(alignment: .topLeading) {
                ItemCard(
                    item: item,
                    isThumbnail: true
                )

                if isSelectable {
                    if selected.contains(item) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                            .padding(5)
                    } else {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.gray)
                            .padding(5)
                    }
                }
            }
        }
    }

    var addOptionsSheet: some View {
        enum AddOption: String, CaseIterable {
            case cameraRoll = "カメラロールから"
            case web = "Webから"
        }

        return SelectSheet(
            options: AddOption.allCases.map(\.rawValue)
        ) {
            switch AddOption(rawValue: $0)! {
            case .cameraRoll:
                activeSheet = .imagePicker
            case .web:
                activeSheet = nil
                navigation.path.append(
                    ItemAddSelectWebSiteScreen()
                )
            }
        }
    }

    var selectSortSheet: some View {
        SelectSheet(
            options: ItemQuery.Sort.allCases.map(\.rawValue),
            currentValue: activeTab?.query.sort.rawValue
        ) { sort in
            if itemStore.tabs.indices.contains(activeTabIndex) {
                itemStore.queries[activeTabIndex].sort = ItemQuery.Sort(rawValue: sort)!
            }
            activeSheet = nil
        }
    }

    var body: some View {
        let spacing: CGFloat = 2
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: numColumns)

        VStack(spacing: 0) {
            ScrollableTabView(
                itemStore.tabs,
                id: \.query.id,
                title: \.query.name
            ) { tab in
                AdBannerContainer {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: spacing) {
                            ForEach(tab.items, id: \.self) { item in
                                itemCard(item)
                            }
                        }
                        .padding(spacing)
                        .padding(.bottom, 70)
                    }
                    .background(Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255))
                }
            } footer: {
                innerFooter
                    .padding(.bottom, 7)
            } onChange: { _, newId in
                if let index = itemStore.tabs.firstIndex(where: { $0.query.id == newId }) {
                    activeTabIndex = index
                }
            }

            bottomBar
        }
        .if(isOnlySelectable) {
            $0
                .navigationTitle("アイテム選択")
                .navigationBarTitleDisplayMode(.inline)
        }
        .alert("本当に削除しますか？", isPresented: $isAlertPresented) {
            Button(role: .cancel) {} label: { Text("戻る") }
            Button(role: .destructive) {
                Task { @MainActor in
                    defer {
                        selected = []
                        isSelectable = false
                    }

                    await snackbarStore.notify(logger) {
                        try await itemStore.delete(selected)
                    }
                }
            } label: { Text("削除する") }
        } message: {
            Text("選択中のアイテムが削除されます。")
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .itemDeleteConfirmOutfits(let outfits):
                ItemDeleteConfirmOutfitsSheet(
                    items: selected,
                    relatedOutfits: outfits
                ) {
                    activeSheet = nil
                }
                .onDisappear {
                    // キャンセルしたときも発動したいので onDecided ではなく、 onDisappear である必要がある
                    isSelectable = false
                    selected = []
                }

            case .imagePicker:
                ImagePicker { images in
                    if images.isEmpty {
                        activeSheet = nil
                        return
                    }

                    let items = images.map {
                        Item(imageSource: .uiImage($0))
                    }

                    navigation.path.append(ItemDetail(
                        items: items,
                        mode: .create
                    ))

                    activeSheet = nil
                }

            case .addOptions:
                addOptionsSheet

            case .selectSort:
                selectSortSheet
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: ItemDetail.self) { $0 }
        .navigationDestination(for: ItemAddSelectWebSiteScreen.self) { $0 }
    }
}

#Preview {
    struct AsyncPreveiw: View {
        @State var isOnlySelectable = false
        @State var selected = [Item]()

        var body: some View {
            DependencyInjector {
                VStack {
                    Button {
                        isOnlySelectable.toggle()
                        selected = []
                    } label: {
                        Text("isOnlySelectable = \(isOnlySelectable)")
                    }

                    Text(selected.map(\.id).joined(separator: ","))

                    if isOnlySelectable {
                        ItemGrid(
                            isOnlySelectable: isOnlySelectable
                        ) {
                            selected = $0
                        }
                    } else {
                        ItemGrid()
                    }
                }
            }
        }
    }

    return AsyncPreveiw()
}
