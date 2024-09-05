//
//  SelectWebImageScreen.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/26.
//

import SwiftUI

struct SelectWebImageScreen: HashableView {
    let imageURLs: [String]
    let spacing: CGFloat = 3
    var onSelected: ([String]) -> Void = { _ in }

    @State private var selected: [String] = []

    var header: some View {
        HStack {
            Text("追加するアイテムを選ぶ")
                .font(.headline)
                .padding(7)
            Spacer()
        }
    }

    var footer: some View {
        RoundRectangleButton(
            text: "決定",
            fontSize: 20,
            radius: 5
        ) {
            onSelected(selected)
        }
        .padding(7)
    }

    func imageCard(_ url: String) -> some View {
        ZStack(alignment: .topTrailing) {
            ImageCard(
                url: url,
                aspectRatio: 1,
                contentMode: .fill
            )

            Button {
                if selected.contains(url) {
                    selected.removeAll { $0 == url }
                } else {
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
        imageURLs: sampleItems.compactMap { $0.imageURL }
    )
}
