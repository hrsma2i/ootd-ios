//
//  OutfitsRow.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/09.
//

import SwiftUI

struct OutfitsRow: View {
    let outfits: [Outfit]
    var size: CGFloat = 300

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(outfits, id: \.self) { outfit in
                    OutfitCard(outfit: outfit)
                        .frame(width: size, height: size)
                }
            }
            .padding()
        }
    }
}

#Preview {
    VStack {
        OutfitsRow(outfits: sampleOutfits)
    }
    .background(.gray)
}
