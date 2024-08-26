//
//  SelectedItemsGrid.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/19.
//

import SwiftUI

struct SelectedItemsGrid: View {
    @EnvironmentObject var navigation: NavigationManager
    @Binding var items: [Item]

    func removeButton(_ item: Item) -> some View {
        Button {
            items = items.filter { $0.id != item.id }
        } label: {
            ZStack {
                Circle()
                    .frame(height: 20)
                    .foregroundColor(.black)
                    .opacity(0.5)

                Image(systemName: "multiply")
                    .font(.system(size: 12))
                    .bold()
                    .foregroundColor(.white)
            }
            .padding(3)
        }
    }

    func itemCard(_ item: Item) -> some View {
        ZStack(alignment: .topTrailing) {
            ItemCard(
                item: item,
                isThumbnail: true
            )

            removeButton(item)
        }
    }

    var body: some View {
        let spacing: CGFloat = 2
        let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 3)

        LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(items, id: \.self) { item in
                itemCard(item)
            }

            AddButton {
                navigation.path.append(ItemGrid(
                    isOnlySelectable: true,
                    selected: items
                ) { items in
                    navigation.path.removeLast()
                    self.items = items
                })
            }
        }
        .padding(spacing)
        .navigationDestination(for: ItemGrid.self) { $0 }
    }
}

#Preview {
    struct PreviewView: View {
        @State var items: [Item] = Array(sampleItems.shuffled().prefix(Int.random(in: 0 ... 4)))

        var body: some View {
            DependencyInjector {
                SelectedItemsGrid(
                    items: $items
                )
                .background(Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255))
            }
        }
    }

    return PreviewView()
}
