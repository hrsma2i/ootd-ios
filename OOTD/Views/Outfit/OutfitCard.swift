//
//  OutfitCard.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/22.
//

import SwiftUI



private extension NSError {
    var isFileNotFoundError: Bool {
        return domain == NSCocoaErrorDomain && code == 260
    }
}

struct OutfitCard: View {
    let outfit: Outfit
    var isThumbnail: Bool = false

    private let aspectRatio: CGFloat = 3 / 4

    var columns: Int {
        outfit.items.count <= 6 ? 2 : 3
    }

    var collage: some View {
        AspectRatioContainer(aspectRatio: aspectRatio) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: columns),
                spacing: 0
            ) {
                ForEach(outfit.items.prefix(9), id: \.self) { item in
                    ItemCard(
                        item: item,
                        isThumbnail: true,
                        padding: 3
                    )
                }
            }
            .padding(20)
        }
        .background(.white)
    }

    var body: some View {
        if let imageSource = outfit.imageSource {
            ImageCard(
                source: imageSource,
                aspectRatio: aspectRatio
            )
        } else {
            collage
        }
    }
}

#Preview {
    ScrollView {
        LazyVGrid(
            columns: Array(repeating: GridItem(), count: 2)
        ) {
            ForEach(sampleOutfits, id: \.self) {
                OutfitCard(outfit: $0)
            }
        }
    }
    .background(Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255))
}
