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
    @State private var condition = OutfitCondition()

    var outfits: [Outfit] {
        outfitStore.filterAndSort(outfitStore.outfits, by: condition)
    }

    var addButton: some View {
        AddButton {
            navigation.path.append(OutfitDetail(
                outfit: Outfit(items: []), mode: .create
            ))
        }
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

    var filterButton: some View {
        RoundRectangleButton(
            text: "絞り込み",
            systemName: "line.horizontal.3.decrease"
        ) {
            navigation.path.append(OutfitConditionDetail(
                condition: $condition
            ))
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

    var deleteButton: some View {
        RoundRectangleButton(
            text: "削除",
            systemName: "trash.fill",
            color: .red
        ) {
            isAlertPresented = true
        }
    }

    var bottomBar: some View {
        VStack {
            Spacer()
            HStack {
                if isSelectable {
                    VStack(alignment: .trailing) {
                        if !selected.isEmpty {
                            HStack {
                                deleteButton
                                Spacer()
                            }
                        }
                        HStack {
                            Spacer()
                            sortButton
                            filterButton
                            cancelButton
                        }
                    }
                } else {
                    Spacer()
                    sortButton
                    filterButton
                    selectButton
                }
            }
            .padding(10)
            .background(.white.opacity(0.5))
        }
    }

    var body: some View {
        return ZStack {
            MasonryGrid(
                columns: 2,
                data: 0 ..< outfits.count + 1
            ) { index in
                if index == 0 {
                    addButton
                } else {
                    outfitCard(outfits[index - 1])
                }
            }
            .background(Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255))

            bottomBar
        }
        .navigationDestination(for: OutfitDetail.self) { $0 }
        .navigationDestination(for: OutfitConditionDetail.self) { $0 }
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
    }
}

#Preview {
    DependencyInjector {
        OutfitGrid()
    }
}
