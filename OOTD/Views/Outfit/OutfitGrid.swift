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
            navigation.path.append(OutfitConditionDetail(
                condition: $condition
            ))
        }
    }

    var sortButton: some View {
        footerButton(
            text: "並べ替え",
            systemName: "arrow.up.arrow.down"
        ) {}
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

    var body: some View {
        let spacing: CGFloat = 2
        return ZStack(alignment: .bottomTrailing) {
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
