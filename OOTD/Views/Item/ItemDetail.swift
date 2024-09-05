//
//  ItemDetail.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/26.
//

import SwiftUI

private let logger = getLogger(#file)

struct ItemDetail: HashableView {
    @State var items: [Item]
    @EnvironmentObject var itemStore: ItemStore
    @EnvironmentObject var navigation: NavigationManager

    // MARK: - private

    private let originalItems: [Item]
    @State private var isAlertPresented: Bool = false

    private enum ActiveSheet: Int, Identifiable {
        case categorySelect

        var id: Int {
            rawValue
        }
    }

    @State private var activeSheet: ActiveSheet?

    init(items: [Item]) {
        self.items = items
        self.originalItems = items
    }

    var hasNewItems: Bool {
        items.contains { $0.id == nil }
    }

    var hasChanges: Bool {
        if hasNewItems {
            return true
        } else {
            return zip(items, originalItems).contains { item, originalItem in
                item != originalItem
            }
        }
    }

    var categoryDisplayed: String {
        if let category = items.first?.category, items.allSatisfy({ $0.category == category }) {
            return category.rawValue
        }
        return "バラバラ"
    }

    var saveButton: some View {
        VStack {
            Spacer()
            RoundRectangleButton(
                text: "保存",
                systemName: "checkmark",
                fontSize: 20
            ) {
                var newItems: [Item] = []
                var existingItems: [Item] = []
                var existingOriginalItems: [Item] = []

                for (i, item) in items.enumerated() {
                    if item.id == nil {
//                        guard item.image != nil else {
//                            logger.error("ID=nil Item has no UIImage")
//                            continue
//                        }
                        newItems.append(item)
                    } else {
                        existingItems.append(item)
                        existingOriginalItems.append(originalItems[i])
                    }
                }

                Task {
                    try await itemStore.create(newItems)
                }
                Task {
                    try await itemStore.update(existingItems, originalItems: existingOriginalItems)
                }

                navigation.path.removeLast()
            }
        }
    }

    var body: some View {
        ZStack {
            ScrollView {
                if items.count == 1, let item = items.first {
                    ItemCard(item: item)
                } else {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(items, id: \.self) { item in
                                ItemCard(item: item)
                            }
                            .frame(height: 250)
                        }
                        .padding(10)
                    }
                }

                HStack {
                    Text("カテゴリー")
                    Spacer()
                    Button {
                        activeSheet = .categorySelect
                    } label: {
                        Text(categoryDisplayed)
                    }
                }
                .padding(20)
            }

            if hasChanges {
                saveButton
            }
        }
        .background(Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255))
        .navigationTitle("アイテム詳細")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if hasChanges {
                        isAlertPresented = true
                    } else {
                        navigation.path.removeLast()
                    }
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.bold)
                        Text("Back")
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .categorySelect:
                CategorySelectSheet { category in
                    activeSheet = nil

                    if let category {
                        // items の要素のプロパティを直接書き換えても再描画されなかったので
                        items = items.map {
                            $0.copyWith(\.category, value: category)
                        }
                    }
                }
            }
        }
        .alert("破棄しますか？", isPresented: $isAlertPresented) {
            Button(role: .cancel) {} label: { Text("編集に戻る") }
            Button(role: .destructive) {
                navigation.path.removeLast()
            } label: { Text("破棄する") }
        } message: {
            Text("このまま戻ると、編集内容がすべて失われます。")
        }
    }
}

#Preview {
    struct SwitchableView: View {
        @State private var isSingle = false

        var body: some View {
            DependencyInjector {
                VStack {
                    Button(action: { isSingle = !isSingle }) {
                        Text("切り替え")
                    }
                    if isSingle {
                        ItemDetail(
                            items: [sampleItems.first!]
                        )
                    } else {
                        ItemDetail(
                            items: Array(sampleItems[0 ... 4])
                        )
                    }
                }
            }
        }
    }

    return SwitchableView()
}
