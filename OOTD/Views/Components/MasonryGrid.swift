//
//  MasonryGrid.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/24.
//

import SwiftUI

struct MasonryGrid<Data, Content>: View where Data: RandomAccessCollection, Content: View {
    let columns: Int
    let data: Data
    var spacing: CGFloat = 3
    @ViewBuilder let content: (Data.Element) -> Content

    @State private var showFavoritesOnly = false

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: spacing) {
                ForEach(0 ..< columns, id: \.self) { col in
                    let items = data.enumerated()
                        .filter { item in
                            item.offset % columns == col
                        }
                    LazyVStack(spacing: spacing) {
                        ForEach(items, id: \.self.offset) { item in
                            content(item.element)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    struct PreviewView: View {
        var body: some View {
            MasonryGrid(
                columns: 2,
                data: sampleItems,
                content: {
                    if case let .url(imageUrl) = $0.imageSource {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                    }
                }
            )
        }
    }

    return DependencyInjector {
        PreviewView()
    }
}
