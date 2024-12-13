//
//  SelectWebItemScreen.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/29.
//

import SwiftUI

private let logger = CustomLogger(#file)

struct SelectWebItemScreen: HashableView {
    @State var items: [Item]

    private let spacing: CGFloat = 3
    @State private var selected: [Item] = []
    @EnvironmentObject var navigation: NavigationManager
    @EnvironmentObject var itemStore: ItemStore
    @EnvironmentObject var snackbarStore: SnackbarStore

    var header: some View {
        HStack {
            Text("保存するアイテムを選ぶ")
                .font(.headline)
                .padding(7)
            Spacer()
        }
    }

    func remove(_ itemsToDelete: [Item]) {
        items = items.filter { item in
            !itemsToDelete.contains { $0.id == item.id }
        }
    }

    func update(_ item: Item) {
        items = items.map {
            guard $0.id == item.id else {
                return $0
            }
            return item
        }
    }

    @ViewBuilder
    var footer: some View {
        if selected.count > 0 {
            RoundRectangleButton(
                text: "保存",
                fontSize: 20,
                radius: 5
            ) {
                Task { @MainActor in
                    // SourceUrl から情報を取得する間も画面をロックしたいので itemStore.create 内で isWriting = true する前にしている
                    itemStore.isWriting = true

                    defer {
                        navigation.path = NavigationPath()
                        itemStore.isWriting = false
                    }

                    let items = await selected.asyncMap { item in
                        do {
                            return try await item.copyWithPropertiesFromSourceUrl()
                        } catch {
                            logger.warning("\(error)")
                            return item
                        }
                    }

                    await snackbarStore.notify(logger) {
                        try await itemStore.create(items)
                    }
                }
            }
            .padding(7)
        }
    }

    func imageCard_(_ item: Item) -> some View {
        Button {
            navigation.path.append(
                WebItemDetail(item: item) { createdItem in
                    remove([createdItem])
                } onBacked: {
                    update($0)
                }
            )
        } label: {
            ImageCard(
                source: item.thumbnailSource
            )
            .border(Color(gray: 0.8))
        }
    }

    @ViewBuilder
    func imageCard(_ item: Item) -> some View {
        imageCard_(item)
            .overlay(alignment: .topLeading) {
                Button {
                    if selected.contains(item) {
                        selected.removeAll { $0.id == item.id }
                    } else {
                        selected.append(item)
                    }
                } label: {
                    Group {
                        if selected.contains(item) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        } else {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .font(.system(size: 25))
                    .padding(5)
                }
            }
    }

    var body: some View {
        AdBannerContainer {
            VStack(spacing: 0) {
                header

                Divider()

                ScrollView {
                    MasonryVGrid(columns: 3, spacing: spacing) {
                        ForEach(items, id: \.self) { item in
                            imageCard(item)
                        }
                    }
                    .padding(.horizontal, spacing)
                }

                Divider()

                footer
            }
            .navigationDestination(for: WebItemDetail.self) { $0 }
        }
    }
}

#Preview {
    DependencyInjector {
        SelectWebItemScreen(
            items: sampleItems
        )
    }
}
