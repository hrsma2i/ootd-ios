//
//  ItemGrid.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/20.
//

import SwiftUI

private let logger = getLogger(#file)

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

    // MARK: - optional

    var isOnlySelectable: Bool
    var numColumns: Int
    @State var selected: [Item]
    var onSelected: ([Item]) -> Void

    // MARK: - private

    @State private var isSelectable: Bool
    @State private var isAlertPresented = false
    @State private var searchText: String = ""
    @State private var sorter: ItemGridTab.Sort? = nil

    private static let defaultTab = ItemGridTab(
        name: "すべて",
        sort: .category
    )

    private enum ActiveSheet: Int, Identifiable {
        case itemDeleteConfirmOutfits
        case imagePicker
        case addOptions
        case selectSort

        var id: Int {
            rawValue
        }
    }

    @State private var activeSheet: ActiveSheet?

    var relatedOutfits: [Outfit] {
        outfitStore.getOutfits(using: selected)
    }

    func tabItems(_ tab: ItemGridTab) -> [Item] {
        var items = itemStore.items
        let keyword = searchText.lowercased()

        if keyword != "" {
            items = items.filter { item in
                item.name.lowercased().contains(keyword)
                    || item.originalDescription?.lowercased().contains(keyword) ?? false
                    || item.originalBrand?.lowercased().contains(keyword) ?? false
                    || item.tags.map {
                        $0.lowercased().contains(keyword)
                    }.contains(true)
            }
        }

        items = tab.apply(items)

        if let sorter {
            items = items.sorted { sorter.compare($0, $1) }
        }

        return items
    }

    // TODO: TabStore を作って、そこから読み書きする
    var tabs: [ItemGridTab] {
        let categories = itemStore.items.map(\.category).unique().sorted()

        let tabs = [
            ItemGrid.defaultTab
        ] + categories.map { category in
            ItemGridTab(
                name: category.rawValue,
                sort: .purchasedOnDescendant,
                filter: .init(
                    category: category
                )
            )
        }

        return tabs
    }

    var sortButton: some View {
        footerButton(
            text: sorter?.rawValue ?? "並べ替え",
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
            color: Color(red: 255 / 255, green: 117 / 255, blue: 117 / 255)
        ) {
            if relatedOutfits.isEmpty {
                isAlertPresented = true
            } else {
                activeSheet = .itemDeleteConfirmOutfits
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
        SearchBar(text: $searchText, placeholder: "検索")
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

    func addOption(_ text: String, action: @escaping () -> Void = {}) -> some View {
        return RoundRectangleButton(
            text: text,
            fontSize: 20,
            radius: 5,
            action: action
        )
    }

    var addOptionsSheet: some View {
        // navigation や sheet を切り替えやすくするため他の View に切り出さない
        VStack {
            addOption(
                "カメラロールから"
            ) {
                activeSheet = .imagePicker
            }

            addOption(
                "Webから"
            ) {
                activeSheet = nil
                navigation.path.append(
                    ItemAddSelectWebSiteScreen()
                )
            }
        }
        .presentationDetents([.fraction(0.18)])
    }

    var selectSortSheet: some View {
        SelectSheet(
            options: ItemGridTab.Sort.allCases.map(\.rawValue)
        ) { sort in
            sorter = ItemGridTab.Sort(rawValue: sort)!
            activeSheet = nil
        }
    }

    var body: some View {
        let spacing: CGFloat = 2
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: numColumns)

        VStack(spacing: 0) {
            ScrollableTabView(
                tabs,
                id: \.name,
                title: \.name
            ) { tab in
                ScrollView {
                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(tabItems(tab), id: \.self) { item in
                            itemCard(item)
                        }
                    }
                    .padding(spacing)
                    .padding(.bottom, 70)
                }
                .background(Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255))
            } footer: {
                innerFooter
                    .padding(.bottom, 7)
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
                Task {
                    do {
                        try await itemStore.delete(selected)
                        selected = []
                    } catch {
                        logger.error("\(error)")
                    }
                }
                isSelectable = false
            } label: { Text("削除する") }
        } message: {
            Text("選択中のアイテムが削除されます。")
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .itemDeleteConfirmOutfits:
                ItemDeleteConfirmOutfitsSheet(
                    items: selected,
                    relatedOutfits: relatedOutfits
                ) {
                    activeSheet = nil
                }
                .onDisappear {
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
