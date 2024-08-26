//
//  OutfitCard.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/22.
//

import SwiftUI

private let logger = getLogger(#file)

struct OutfitCard: View {
    let outfit: Outfit

    var columns: Int {
        outfit.items.count <= 6 ? 2 : 3
    }

    var collageAspectRatio: CGFloat? {
        outfit.items.isEmpty ? 1 : nil
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
        if let image = outfit.image {
            ImageCard(
                uiImage: image
            )
        } else if let imageURL = outfit.imageURL {
            ImageCard(
                url: imageURL
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
