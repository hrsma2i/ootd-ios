//
//  SelectWebImageScreen.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/26.
//

import SwiftUI



struct SelectWebImageScreen: HashableView {
    @State var imageURLs: [String]
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
            source: .url(url)
        ) { _ in
            imageURLs = imageURLs.filter { imageUrl in
                imageUrl != url
            }

            logger.warning("failed to load image from \(url)")
        }
        .border(Color(gray: 0.8))
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
            imageCard_(url)
                .overlay(alignment: .topLeading) {
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
                        Group {
                            if selected.contains(url) {
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
    }

    var body: some View {
        AdBannerContainer {
            VStack(spacing: 0) {
                header

                Divider()

                ScrollView {
                    MasonryVGrid(columns: 3, spacing: spacing) {
                        ForEach(imageURLs, id: \.self) { url in
                            imageCard(url)
                        }
                    }
                    .padding(.horizontal, spacing)
                }

                Divider()

                footer
            }
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
