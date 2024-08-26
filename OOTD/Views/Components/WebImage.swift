//
//  WebImage.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/21.
//

import CachedAsyncImage
import SwiftUI

private let logger = getLogger(#file)

struct WebImage: View {
    let url: String
    var radius: CGFloat = 0
    var aspectRatio: CGFloat? = nil
    var shadow: Bool = false
    var contentMode: ContentMode = .fill
    var backgroundColor: Color = .white
    var padding: CGFloat = 0

    var body: some View {
        CachedAsyncImage(url: URL(string: url)) { phase in
            if let image = phase.image {
                // Center crop
                // https://stackoverflow.com/questions/63651077/how-to-center-crop-an-image-in-swiftui
                if aspectRatio != nil {
                    Rectangle()
                        .foregroundColor(backgroundColor)
                        .aspectRatio(aspectRatio, contentMode: .fit)
                        .overlay(
                            image
                                .resizable()
                                .aspectRatio(nil, contentMode: contentMode)
                                .padding(padding)
                        )
                        .clipShape(Rectangle())
                } else {
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                        .padding(padding)
                        .background(backgroundColor)
                }
            } else if let error = phase.error {
                Rectangle()
                    .foregroundColor(backgroundColor)
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .overlay(
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
                    )
                    .clipShape(Rectangle())
                    .task {
                        logger.error("\(error.localizedDescription)")
                    }
            } else {
                Rectangle()
                    .foregroundColor(backgroundColor)
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .overlay(
                        ProgressView()
                    )
                    .clipShape(Rectangle())
            }
        }
        .cornerRadius(radius)
        .if(shadow) { view in
            view
                .shadow(color: .black.opacity(0.1), radius: 1.5, x: 0, y: 1)
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 6)
        }
    }
}

#Preview {
    let url = "https://publicdomainq.net/images/201802/01s/publicdomainq-0018423cpl.jpg"
    let height: CGFloat = 100
    let radius: CGFloat = 7
    let padding: CGFloat = 10

    return ScrollView {
        VStack {
            HStack {
                Text("aspectRatio: nil")
                Spacer()
                WebImage(
                    url: url,
                    radius: radius
                )
                .frame(height: height)
            }

            Divider()

            HStack {
                Text("aspectRatio: 1")
                Spacer()
                WebImage(
                    url: url,
                    radius: radius,
                    aspectRatio: 1,
                    shadow: true
                )
                .frame(height: height)
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("aspectRatio: 1")
                    Text("contentMode: fit")
                    Text("shadow: true")
                }
                Spacer()
                WebImage(
                    url: url,
                    radius: radius,
                    aspectRatio: 1,
                    shadow: true,
                    contentMode: .fit
                )
                .frame(height: height)
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("aspectRatio: 1")
                    Text("contentMode: fit")
                    Text("shadow: true")
                    Text("padding: \(Int(padding))")
                }
                Spacer()
                WebImage(
                    url: url,
                    radius: radius,
                    aspectRatio: 1,
                    shadow: true,
                    contentMode: .fit,
                    padding: padding
                )
                .frame(height: height)
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("aspectRatio: 1")
                    Text("contentMode: fit")
                    Text("shadow: true")
                    Text("padding: \(Int(padding))")
                }
                Spacer()
                WebImage(
                    url: url,
                    radius: radius,
                    shadow: true,
                    contentMode: .fit,
                    padding: padding
                )
                .frame(height: height)
            }

            Divider()

            HStack {
                Text("aspectRatio: 3/4")
                Spacer()
                WebImage(
                    url: url,
                    radius: radius,
                    aspectRatio: 3 / 4
                )
                .frame(height: height)
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("error")
                    Text("aspectRatio: nil")
                }
                Spacer()
                WebImage(
                    url: "invalid url",
                    radius: radius
                )
                .border(.foreground)
                .frame(height: height)
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("error")
                    Text("aspectRatio: 3/4")
                }
                Spacer()
                WebImage(
                    url: "invalid url",
                    radius: radius,
                    aspectRatio: 3 / 4
                )
                .border(.foreground)
                .frame(height: height)
            }
        }
        .padding()
    }
}
