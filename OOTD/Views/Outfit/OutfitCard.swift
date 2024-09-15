//
//  OutfitCard.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/22.
//

import SwiftUI

private let logger = getLogger(#file)

private extension NSError {
    var isFileNotFoundError: Bool {
        return domain == NSCocoaErrorDomain && code == 260
    }
}

struct OutfitCard: View {
    let outfit: Outfit
    var isThumbnail: Bool = false

    var columns: Int {
        outfit.items.count <= 6 ? 2 : 3
    }

    var collageAspectRatio: CGFloat? {
        outfit.items.isEmpty ? 1 : nil
    }

    // TODO: Image 内に image 取得メソッドを持たせ、描画時に取得したほうがいいか？Storage を protocol で抽象化して、 Firebase Storage にも切り替えられるようにする？
    var image: UIImage? {
        if let image = outfit.image {
            return image
        }

        guard let imagePath = outfit.imagePath,
              let thumbnailPath = outfit.thumbnailPath
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
        } catch let error as NSError where error.isFileNotFoundError {
            // collage だけでスナップ画像がないことはよくあることなのでいちいち warning を吐かない
            return nil
        } catch {
            logger.warning("\(error)")
            return nil
        }
    }

    var collage: some View {
        AspectRatioContainer(aspectRatio: collageAspectRatio) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: columns),
                spacing: 0
            ) {
                ForEach(outfit.items, id: \.self) { item in
                    ItemCard(
                        item: item,
                        isThumbnail: true,
                        padding: 3
                    )
                }
            }
            .padding(12)
        }
        .background(.white)
    }

    var body: some View {
        if let image {
            ImageCard(
                uiImage: image
            )
        } else {
            collage
        }
    }
}

#Preview {
    MasonryGrid(
        columns: 2,
        data: sampleOutfits
    ) {
        OutfitCard(outfit: $0)
    }
    .background(Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255))
}
