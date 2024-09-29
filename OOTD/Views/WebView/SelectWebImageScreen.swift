//
//  SelectWebImageScreen.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/26.
//

import SwiftUI

struct SelectWebImageScreen: HashableView {
    let imageURLs: [String]
    var limit: Int = .max
    var onSelected: ([String]) -> Void = { _ in }

    private let spacing: CGFloat = 3
    @State private var selected: [String] = []

    var header: some View {
        HStack {
            Text("画像を選ぶ")
                .font(.headline)
                .padding(7)
            Spacer()
        }
    }

    @ViewBuilder
    var footer: some View {
        if limit != 1, selected.count > 0 {
            RoundRectangleButton(
                text: "決定",
                fontSize: 20,
                radius: 5
            ) {
                onSelected(selected)
            }
            .padding(7)
        }
    }

    func imageCard_(_ url: String) -> some View {
        ImageCard(
            source: .url(url),
            aspectRatio: 1,
            contentMode: .fill
        )
    }

    @ViewBuilder
    func imageCard(_ url: String) -> some View {
        if limit == 1 {
            Button {
                onSelected([url])
            } label: {
                imageCard_(url)
            }
        } else {
            ZStack(alignment: .topTrailing) {
                imageCard_(url)

                Button {
                    if selected.contains(url) {
                        selected.removeAll { $0 == url }
                    } else {
                        if selected.count >= limit {
                            selected.removeFirst()
                        }
                        selected.append(url)
                    }
                } label: {
                    if selected.contains(url) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 25))
                            .padding(5)
                    } else {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.gray)
                            .font(.system(size: 25))
                            .padding(5)
                    }
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: 3), spacing: spacing) {
                    ForEach(imageURLs, id: \.self) { url in
                        imageCard(url)
                    }
                }
            }

            Divider()

            footer
        }
    }
}

#Preview {
    SelectWebImageScreen(
        imageURLs: sampleItems.compactMap {
            guard case let .url(url) = $0.imageSource else {
                return nil
            }
            return url
        }
    )
}
