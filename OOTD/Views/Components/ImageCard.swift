//
//  ImageCard.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/26.
//

import CachedAsyncImage
import SwiftUI
import UIKit

struct ImageCard: View {
    let source: ImageSource
    var aspectRatio: CGFloat?
    var padding: CGFloat = 0
    var contentMode: ContentMode = .fit
    var backgroundColor: Color = .white
    var onError: ((ImageSource) -> Void)? = { _ in }

    @State var image: UIImage? = nil
    @State var isError = false

    private var storage: FileStorage {
        switch Config.DATA_SOURCE {
        case .swiftData:
            return LocalStorage.applicationSupport
        case .sample:
            return InMemoryStorage()
        }
    }

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
        .task {
            if let onError {
                onError(source)
            }
        }
    }

    var loadingView: some View {
        AspectRatioContainer(aspectRatio: aspectRatio ?? 1) {
            ProgressView()
        }
    }

    var body: some View {
        Group {
            switch source {
            case .storagePath, .uiImage:
                if let image {
                    imageView(Image(uiImage: image))
                } else if isError {
                    errorView
                } else {
                    loadingView
                }

            case .url(let url):
                CachedAsyncImage(url: URL(string: url)) { phase in
                    if let image = phase.image {
                        imageView(image)
                    } else if let error = phase.error {
                        errorView
                            .task {
                                logger.critical("\(error.localizedDescription). url: \(url)")
                            }
                    } else {
                        loadingView
                    }
                }
            }
        }
        .task {
            Task {
                do {
                    switch source {
                    case .storagePath, .uiImage:
                        image = try await source.getUiImage(storage: storage)
                    default:
                        break
                    }
                } catch {
                    isError = true
                }
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
                    ImageCard(source: .uiImage(uiImage))
                        .frame(height: 200)
                }

                ImageCard(source: .url(url))
                    .frame(height: 200)

                ImageCard(source: .url(url), aspectRatio: 1)
                    .frame(height: 200)

                ImageCard(source: .url(url), aspectRatio: 1, padding: 12)
                    .frame(height: 200)

                ImageCard(source: .url(url), aspectRatio: 1, contentMode: .fill)
                    .frame(height: 200)
            }
            .task {
                uiImage = try! await downloadImage(url)
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
