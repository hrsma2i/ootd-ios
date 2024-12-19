//
//  ItemCard.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/22.
//

import CachedAsyncImage
import SwiftUI

struct ItemCard: View {
    // TODO: 削除してよさそう。ImageCard で十分そう
    let item: Item
    var isThumbnail: Bool = false
    var padding: CGFloat = 12
    var aspectRatio: CGFloat? = 1.0

    var body: some View {
        ImageCard(
            source: isThumbnail ? item.thumbnailSource : item.imageSource,
            aspectRatio: aspectRatio,
            padding: padding
        )
    }
}

#Preview {
    struct PreviewView: View {
        @State var itemHasUIImage: Item?
        let itemHasURL: Item = sampleItems.filter {
            guard case let .url(imageUrl) = $0.imageSource else {
                return false
            }
            return imageUrl.contains("white_ma1")
        }.first!
        let spacing: CGFloat = 5

        func row(_ title: String, content: @escaping () -> some View) -> some View {
            HStack {
                Text(title)
                Spacer()
                content()
            }
            .frame(height: 120)
        }

        var body: some View {
            let itemHasInvalidURL = itemHasURL.copyWith(\.imageSource, value: .url("error url"))

            return ScrollView {
                if let itemHasUIImage {
                    row("UIImage") {
                        ItemCard(item: itemHasUIImage)
                    }
                }
                row("URL") {
                    ItemCard(item: itemHasURL)
                }
                row("invalid URL") {
                    ItemCard(item: itemHasInvalidURL)
                }
                row("loading") {
                    AspectRatioContainer(aspectRatio: 1) {
                        ProgressView()
                    }
                    .background(.white)
                }
            }
            .padding(spacing)
            .background(.gray)
            .task {
                let image = try! await itemHasURL.imageSource.getUiImage(storage: nil)
                itemHasUIImage = .init(imageSource: .uiImage(image))
            }
        }
    }

    return PreviewView()
}
