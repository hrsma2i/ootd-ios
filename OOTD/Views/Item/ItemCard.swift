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

    // TODO: Image 内に image 取得メソッドを持たせ、描画時に取得したほうがいいか？Storage を protocol で抽象化して、 Firebase Storage にも切り替えられるようにする？
    var image: UIImage? {
        if let image = item.image {
            return image
        }

        guard let imagePath = item.imagePath,
              let thumbnailPath = item.thumbnailPath
        else {
            return nil
        }

        do {
            if isThumbnail {
                let thumbnail = try LocalStorage.loadImage(from: thumbnailPath)
                return thumbnail
            } else {
                let image = try LocalStorage.loadImage(from: imagePath)
                return image
            }
        } catch {
            logger.warning("\(error)")
            return nil
        }
    }

    var body: some View {
        ImageCard(
            uiImage: image,
            url: url,
            aspectRatio: 1,
            padding: padding
        )
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
