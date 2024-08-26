//
//  ItemCard.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/22.
//

import CachedAsyncImage
import SwiftUI

private let logger = getLogger(#file)

struct ItemCard: View {
    let item: Item
    var isThumbnail: Bool = false
    var padding: CGFloat = 12

    var url: String? {
        isThumbnail ? item.thumbnailURL ?? item.imageURL : item.imageURL
    }

    func imageView(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .padding(padding)
    }

    var errorView: some View {
        VStack(spacing: 5) {
            Image(systemName: "multiply.circle.fill")
            // フォントサイズを View のサイズに合わせる
            // https://stackoverflow.com/questions/57035746/how-to-scale-text-to-fit-parent-view-with-swiftui
            Text("読み込みエラー")
                .font(.system(size: 500))
                .minimumScaleFactor(0.01)
                .lineLimit(1)
                .font(.callout)
        }
        .foregroundColor(.red)
    }

    @ViewBuilder
    var body: some View {
        AspectRatioContainer(aspectRatio: 1) {
            if let image = item.image {
                imageView(Image(uiImage: image))
            } else if let url {
                CachedAsyncImage(url: URL(string: url)) { phase in
                    if let image = phase.image {
                        imageView(image)
                    } else if let error = phase.error {
                        errorView
                            .task {
                                logger.error("\(error.localizedDescription)")
                            }
                    } else {
                        ProgressView()
                    }
                }
            } else {
                errorView
            }
        }
        .background(.white)
    }
}

#Preview {
    struct PreviewView: View {
        @State var itemHasUIImage: Item = .init()
        let itemHasURL: Item = sampleItems.filter { $0.id == "white_ma1" }.first!
        let spacing: CGFloat = 5
        let itemBothNil: Item = .init()

        func row(_ title: String, content: @escaping () -> some View) -> some View {
            HStack {
                Text(title)
                Spacer()
                content()
            }
            .frame(height: 120)
        }

        var body: some View {
            let itemHasInvalidURL = itemHasURL.copyWith(\.imageURL, value: "error url")

            return ScrollView {
                row("UIImage") {
                    ItemCard(item: itemHasUIImage)
                }
                row("URL") {
                    ItemCard(item: itemHasURL)
                }
                row("invalid URL") {
                    ItemCard(item: itemHasInvalidURL)
                }
                row("UIImage = nil && URL = nil") {
                    ItemCard(item: itemBothNil)
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
                let url = itemHasURL.imageURL!
                let image = try! await downloadImage(url)
                itemHasUIImage.image = UIImage(data: image)
            }
        }
    }

    return PreviewView()
}
