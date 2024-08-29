//
//  ItemDeleteConfirmOutfitsScreen.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/09.
//

import SwiftUI

private let logger = getLogger(#file)

struct ItemDeleteConfirmOutfitsSheet: HashableView {
    let items: [Item]
    let relatedOutfits: [Outfit]
    @EnvironmentObject var itemStore: ItemStore
    @EnvironmentObject var outfitStore: OutfitStore

    // MARK: - optional

    var onDecided: () -> Void = {}

    // MARK: - private

    @State private var isAlsoOutfitDeleteAlertPresented = false
    @State private var isOnlyItemDeleteAlertPresented = false

    var onlyItemDeletedOutfits: [Outfit] {
        relatedOutfits.map { outfit in
            outfit.copyWith(
                \.items,
                value: outfit.items.filter { item in
                    !items.contains { $0.id == item.id }
                }
            )
        }
    }

    func deleteButton(_ title: String, color: Color, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 5)
                .frame(width: CGFloat(16 * title.count + 15), height: 30)
                .foregroundColor(color)
                .overlay(
                    Text(title)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                )
                .padding(.horizontal)
        }
    }

    func row<T: Hashable>(title: String, data: [T], @ViewBuilder content: @escaping (T) -> some View) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .padding(.horizontal, 10)

            ScrollView(.horizontal) {
                HStack {
                    ForEach(data, id: \.self) {
                        content($0)
                    }
                }
                .padding(.horizontal, 10)
            }
        }
    }

    var header: some View {
        HStack {
            Spacer()
            Text("関連コーデも削除するか選んでください")
                .font(.headline)
                .padding()
            Spacer()
        }
        .background(.white)
    }

    var itemsRow: some View {
        row(
            title: "削除するアイテム",
            data: items
        ) { item in
            ItemCard(
                item: item,
                isThumbnail: true
            )
            .frame(height: 100)
        }
    }

    var outfitsRow: some View {
        row(
            title: "使われているコーデ",
            data: relatedOutfits
        ) { outfit in
            OutfitCard(outfit: outfit)
                .frame(width: 150, height: 150)
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            header

            itemsRow

            outfitsRow

            Spacer()

            deleteButton("コーデからアイテムだけ削除する", color: .black) {
                isOnlyItemDeleteAlertPresented = true
            }

            deleteButton("コーデも削除する", color: .red) {
                isAlsoOutfitDeleteAlertPresented = true
            }

            Spacer()
        }
        .background(Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255))
        .alert("コーデも削除しますか？", isPresented: $isAlsoOutfitDeleteAlertPresented) {
            Button(role: .cancel) {} label: { Text("戻る") }
            Button(role: .destructive) {
                Task {
                    do {
                        try await outfitStore.delete(relatedOutfits)
                        try await itemStore.delete(items)
                    } catch {
                        logger.error("\(error)")
                    }
                }
                onDecided()
            } label: { Text("削除する") }
        } message: {
            Text("選択したアイテムと、それを使った表示中のコーデも全て削除されます")
        }
        .alert("コーデからアイテムだけ削除しますか？", isPresented: $isOnlyItemDeleteAlertPresented) {
            Button(role: .cancel) {} label: { Text("戻る") }
            Button(role: .destructive) {
                Task {
                    do {
                        try await outfitStore.update(onlyItemDeletedOutfits, originalOutfits: relatedOutfits)
                        try await itemStore.delete(items)
                    } catch {
                        logger.error("\(error)")
                    }
                }
                onDecided()
            } label: { Text("削除する") }
        } message: {
            Text("選択したアイテムだけ削除され、それを使ったコーデは表示中のように残ります")
        }
        .presentationDetents([.fraction(0.8)])
    }
}

#Preview {
    @MainActor
    struct PreviewView: View {
        let outfitStore = OutfitStore()
        let itemStore = ItemStore()
        let items = sampleItems.filter { ["black_cocoon_denim", "white_ma1"].contains($0.id) }
        @State private var outfits: [Outfit] = []
        @State private var path = NavigationPath()
        @State private var isSheetPresented = true

        var body: some View {
            Button {
                isSheetPresented = true
            } label: {
                Text("シートを表示")
            }
            .sheet(isPresented: $isSheetPresented) {
                ItemDeleteConfirmOutfitsSheet(
                    items: items,
                    relatedOutfits: outfits
                ) {
                    isSheetPresented = false
                }
                .task {
                    do {
                        try await itemStore.fetch()
                        try await outfitStore.fetch()
                    } catch {}

                    outfitStore.joinItems(itemStore.items)

                    outfits = outfitStore.getOutfits(using: items)
                }
            }
            .environmentObject(itemStore)
            .environmentObject(outfitStore)
        }
    }

    return PreviewView()
}
