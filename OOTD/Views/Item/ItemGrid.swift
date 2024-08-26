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
    @State private var isImagePickerPresented = false
    @State private var isAlertPresented = false

    private enum ActiveSheet: Int, Identifiable {
        case itemDeleteConfirmOutfits
        case categorySelect

        var id: Int {
            rawValue
        }
    }

    @State private var activeSheet: ActiveSheet?
    @State private var filter = ItemFilter()

    var relatedOutfits: [Outfit] {
        outfitStore.getOutfits(using: selected)
    }

    var items: [Item] {
        itemStore.filter(itemStore.items, by: filter)
    }

    var categoryFilterButton: some View {
        RoundRectangleButton(
            text: filter.category?.rawValue ?? "カテゴリー", systemName: "line.horizontal.3.decrease",
            color: filter.category == nil ? .black : .blue
        ) {
            activeSheet = .categorySelect
        }
    }

    var sortButton: some View {
        RoundRectangleButton(
            text: "並べ替え",
            systemName: "arrow.up.arrow.down"
        ) {}
    }

    var selectButton: some View {
        RoundRectangleButton(
            text: "選択",
            systemName: "checkmark.square"
        ) {
            isSelectable = true
        }
    }

    var cancelButton: some View {
        RoundRectangleButton(
            text: "戻る",
            systemName: "arrow.uturn.left"
        ) {
            isSelectable = false
            selected = []
        }
    }

    var editButton: some View {
        RoundRectangleButton(
            text: "編集",
            systemName: "pencil"
        ) {
            navigation.path.append(ItemDetail(
                items: selected
            ))

            isSelectable = false
            selected = []
        }
    }

    var deleteButton: some View {
        RoundRectangleButton(
            text: "削除",
            systemName: "trash.fill",
            color: .red
        ) {
            if relatedOutfits.isEmpty {
                isAlertPresented = true
            } else {
                activeSheet = .itemDeleteConfirmOutfits
            }
        }
    }

    var decideButton: some View {
        RoundRectangleButton(
            text: "決定",
            systemName: "checkmark"
        ) {
            onSelected(selected)
        }
    }

    var bottomBar: some View {
        VStack(spacing: 0) {
            Spacer()
            if !isOnlySelectable, isSelectable, !selected.isEmpty {
                HStack {
                    editButton
                    Spacer()
                    deleteButton
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .background(.white.opacity(0.5))
            }
            ScrollView(.horizontal) {
                HStack {
                    if isOnlySelectable {
                        decideButton
                    } else {
                        if isSelectable {
                            cancelButton
                        } else {
                            selectButton
                        }
                    }

                    sortButton
                    categoryFilterButton
                }
                .padding(10)
            }
            .background(.white.opacity(0.5))
        }
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
                    items: [item]
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

    var body: some View {
        let spacing: CGFloat = 2
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: numColumns)

        ZStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: spacing) {
                    if !isOnlySelectable {
                        AddButton {
                            isImagePickerPresented = true
                        }
                    }

                    ForEach(items, id: \.self) { item in
                        itemCard(item)
                    }
                }
                .padding(spacing)
            }
            .background(Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255))

            bottomBar
        }
        .if(isOnlySelectable) {
            $0
                .navigationTitle("アイテム選択")
                .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(isPresented: $isImagePickerPresented) { images in
                if images.isEmpty { return }

                let items = images.map {
                    Item(image: $0)
                }

                navigation.path.append(ItemDetail(
                    items: items
                ))
            }
        }
        .alert("本当に削除しますか？", isPresented: $isAlertPresented) {
            Button(role: .cancel) {} label: { Text("戻る") }
            Button(role: .destructive) {
                isSelectable = false

                Task {
                    do {
                        try await itemStore.delete(selected)
                    } catch {
                        logger.error("\(error)")
                    }
                }
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

            case .categorySelect:
                CategorySelectSheet(
                    allowUncategorized: true,
                    allowNil: true
                ) { category in
                    activeSheet = nil
                    filter.category = category
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: ItemDetail.self) { $0 }
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

                    Text(selected.compactMap(\.id).joined(separator: ","))

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
