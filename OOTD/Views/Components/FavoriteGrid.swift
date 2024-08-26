//
//  FavoriteGrid.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/25.
//

import CachedAsyncImage
import SwiftUI

private let logger = getLogger(#file)

enum SpecialTag: String, CaseIterable {
    case uncategorized = "未分類"
    case all = "すべてのお気に入り"

    static func contains(_ tag: String) -> Bool {
        allCases.contains { $0.rawValue == tag }
    }
}

struct FavoriteGrid: HashableView {
    let tag: String
    @State private var selected: [Favorite] = []
    @State private var isSelectable = false
    @State private var isAddOptionsSheetPresented = false
    @State private var isDeleteAlertPresented = false
    @EnvironmentObject var navigation: NavigationManager
    @EnvironmentObject var favoriteStore: FavoriteStore

    var favorites: [Favorite] {
        switch SpecialTag(rawValue: tag) {
        case .uncategorized:
            return favoriteStore.favorites.filter { $0.tags.isEmpty }
        case .all:
            return favoriteStore.favorites
        default:
            return favoriteStore.favorites.filter { $0.tags.contains(tag) }
        }
    }

    func favoriteCard(_ favorite: Favorite) -> some View {
        Button(action: {
            if isSelectable {
                if selected.contains(favorite) {
                    selected.removeAll { $0 == favorite }
                } else {
                    selected.append(favorite)
                }
            } else {
                navigation.path.append(FavoriteDetail(favorites: [favorite]))
            }
        }) {
            ZStack(alignment: .topLeading) {
                if let url = favorite.scrap?.thumbnailURL {
                    ImageCard(url: url)
                } else {
                    let _ = assertionFailure("favorite.scrap.thumbnailURL is nil in FavoriteGrid")
                    EmptyView()
                }

                if isSelectable {
                    if selected.contains(favorite) {
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
            navigation.path.append(FavoriteDetail(
                favorites: selected
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
            isDeleteAlertPresented = true
        }
    }

    var footer: some View {
        VStack(spacing: 0) {
            Divider()

            if isSelectable, !selected.isEmpty {
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
                    if isSelectable {
                        cancelButton
                    } else {
                        selectButton
                    }
                }
                .padding(10)
            }
            .background(.white.opacity(0.5))
        }
    }

    var removeTagButton: some View {
        Button {
            isSelectable = false

            let favorites = selected.map { favorite in
                favorite.copyWith(\.tags, value: favorite.tags.filter { $0 != tag })
            }

            Task {
                do {
                    try await favoriteStore.update(favorites)
                } catch {
                    logger.error("\(error)")
                }
            }

            selected = []
        } label: { Text("\"\(tag)\" から外す") }
    }

    var deleteFavoriteButton: some View {
        Button(role: .destructive) {
            isSelectable = false

            // ここでコピーしとかないと後の selected = [] で何も削除されない
            let favorites = selected

            Task {
                do {
                    try await favoriteStore.delete(favorites)
                } catch {
                    logger.error("\(error)")
                }
            }

            selected = []
        } label: { Text("お気に入りから削除する") }
    }

    func deleteAlert(content: some View) -> some View {
        return content
            .alert("", isPresented: $isDeleteAlertPresented) {
                if !SpecialTag.contains(tag) {
                    removeTagButton
                }
                deleteFavoriteButton
                Button(role: .cancel) {} label: { Text("戻る") }
            } message: {
                var message = "お気に入りから削除しますか？"
                if !SpecialTag.contains(tag) {
                    message = "選択中のものを\"\(tag)\"から外しますか？それとも" + message
                }

                return Text(message)
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            MasonryGrid(
                columns: 2,
                data: favorites,
                spacing: 2,
                content: { favorite in
                    favoriteCard(favorite)
                }
            )
            .background(Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255))

            footer
        }
        .functionalModifier(deleteAlert)
        .navigationTitle(tag)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: FavoriteDetail.self) { $0 }
        .navigationDestination(for: WebViewWithProgressBar.self) { $0 }
        .navigationDestination(for: SelectWebImageScreen.self) { $0 }
        .navigationDestination(for: WebViewImportInstagramCollection.self) { $0 }
    }
}

#Preview {
    DependencyInjector {
        FavoriteGrid(tag: "半袖チェックシャツ")
    }
}
