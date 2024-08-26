//
//  ImageCard.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/26.
//

import CachedAsyncImage
import SwiftUI
import UIKit

private let logger = getLogger(#file)

struct ImageCard: View {
    var uiImage: UIImage?
    var url: String?
    var aspectRatio: CGFloat?
    var padding: CGFloat = 0
    var contentMode: ContentMode = .fit
    var backgroundColor: Color = .white

    func imageView(_ image: Image) -> some View {
        AspectRatioContainer(aspectRatio: aspectRatio) {
            image
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .padding(padding)
        }
        .background(backgroundColor)
    }

    var errorView: some View {
        AspectRatioContainer(aspectRatio: aspectRatio ?? 1) {
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
    }

    var loadingView: some View {
        AspectRatioContainer(aspectRatio: aspectRatio ?? 1) {
            ProgressView()
        }
    }

    var body: some View {
        if let uiImage {
            imageView(Image(uiImage: uiImage))
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
                    loadingView
                }
            }
        } else {
            errorView
                .task {
                    logger.error("uiImage == nil && url == nil")
                }
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State var uiImage: UIImage?
        let url = "https://images.wear2.jp/coordinate/rliwyvYY/0r5BWoTz/1679204559_500.jpg"
        var body: some View {
            ScrollView {
                if let uiImage {
                    ImageCard(uiImage: uiImage)
                        .frame(height: 200)
                }

                ImageCard(url: url)
                    .frame(height: 200)

                ImageCard(url: url, aspectRatio: 1)
                    .frame(height: 200)

                ImageCard(url: url, aspectRatio: 1, padding: 12)
                    .frame(height: 200)

                ImageCard(url: url, aspectRatio: 1, contentMode: .fill)
                    .frame(height: 200)

                ImageCard()
                    .frame(height: 200)
            }
            .task {
                let imageData = try! await downloadImage(url)
                uiImage = UIImage(data: imageData)
            }
        }
    }

    return HStack {
        Spacer()
        PreviewView()
        Spacer()
    }
    .background(.gray)
}
