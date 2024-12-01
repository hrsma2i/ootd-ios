//
//  OutfitGrid.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/22.
//

import SwiftUI

private let logger = getLogger(#file)

struct OutfitGrid: View {
    @EnvironmentObject var outfitStore: OutfitStore
    @EnvironmentObject var navigation: NavigationManager
    let numColumns: Int = 2

    @State private var isSelectable = false
    @State private var selected: [Outfit] = []
    @State private var isAlertPresented = false
    @State private var tab = OutfitGridTab(
        name: "すべて",
        sort: .createdAtAscendant
    )
    @State private var activeSheet: Sheet?
    enum Sheet: Int, Identifiable {
        case selectSort

        var id: Int {
            rawValue
        }
    }

    @State private var searchText: String = ""

    var outfits: [Outfit] {
        var outfits = outfitStore.outfits
        let keyword = searchText.lowercased()

        if keyword != "" {
            outfits = outfits.filter { outfit in
                outfit.items.map {
                    $0.name.lowercased().contains(keyword)
                }.contains(true)
                    || outfit.tags.map {
                        $0.lowercased().contains(keyword)
                    }.contains(true)
            }
        }

        return tab.apply(outfits)
    }

    func outfitCard(_ outfit: Outfit) -> some View {
        Button {
            if isSelectable {
                if selected.contains(outfit) {
                    selected.removeAll { $0 == outfit }
                } else {
                    selected.append(outfit)
                }
            } else {
                navigation.path.append(OutfitDetail(
                    outfit: outfit,
                    mode: .update
                ))
            }
        } label: {
            ZStack(alignment: .topLeading) {
                OutfitCard(outfit: outfit)

                if isSelectable {
                    if selected.contains(outfit) {
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

    var addButton: some View {
        footerButton(
            text: "追加",
            systemName: "plus"
        ) {
            navigation.path.append(OutfitDetail(
                outfit: Outfit(items: []), mode: .create
            ))
        }
    }

    var filterButton: some View {
        footerButton(
            text: "絞り込み",
            systemName: "line.horizontal.3.decrease"
        ) {
            navigation.path.append(
                OutfitGridTabDetail(
                    tab: tab
                ) {
                    tab = $0
                }
            )
        }
    }

    var sortButton: some View {
        footerButton(
            text: tab.sort.rawValue,
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

    var deleteButton: some View {
        footerButton(
            text: "一括削除",
            systemName: "trash.fill",
            color: Color(red: 255 / 255, green: 117 / 255, blue: 117 / 255)
        ) {
            isAlertPresented = true
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

    var bottomBar: some View {
        HStack(spacing: 0) {
            if isSelectable {
                if !selected.isEmpty {
                    deleteButton
                }
                cancelButton
            } else {
                addButton
                selectButton
            }
            sortButton
            filterButton
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .foregroundColor(.accent)
                .shadow(radius: 3)
        }
        .padding(.trailing, 10)
        .padding(.bottom, 7)
    }

    var selectSortSheet: some View {
        SelectSheet(
            options: OutfitGridTab.Sort.allCases.map(\.rawValue),
            currentValue: tab.sort.rawValue
        ) { sort in
            tab.sort = OutfitGridTab.Sort(rawValue: sort)!
            activeSheet = nil
        }
    }

    var searchBar: some View {
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

    var body: some View {
        let spacing: CGFloat = 2
        return AdBannerContainer {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2),
                            spacing: spacing
                        ) {
                            ForEach(outfits, id: \.self) { outfit in
                                outfitCard(outfit)
                            }
                        }
                        .padding(.bottom, 70)
                        .padding(spacing)
                    }
                    .defaultScrollAnchor(.bottom)
                    .background(Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255))

                    bottomBar
                }

                Divider()

                searchBar
                    .padding(.top, 10)
            }
        }
        .navigationDestination(for: OutfitDetail.self) { $0 }
        .navigationDestination(for: OutfitGridTabDetail.self) { $0 }
        .alert("本当に削除しますか？", isPresented: $isAlertPresented) {
            Button(role: .cancel) {} label: { Text("戻る") }
            Button(role: .destructive) {
                isSelectable = false

                Task {
                    do {
                        try await outfitStore.delete(selected)
                    } catch {
                        logger.error("\(error)")
                    }
                }
            } label: { Text("削除する") }
        } message: {
            Text("選択中のコーデが削除されます。")
        }
        .sheet(item: $activeSheet) {
            switch $0 {
            case .selectSort:
                selectSortSheet
            }
        }
    }
}

#Preview {
    DependencyInjector {
        OutfitGrid()
    }
}
