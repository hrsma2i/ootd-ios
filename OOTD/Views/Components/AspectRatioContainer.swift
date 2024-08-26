//
//  AspectRatioContainer.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/23.
//

import SwiftUI

struct AspectRatioContainer<Content: View>: View {
    var aspectRatio: CGFloat?
    var content: () -> Content

    init(aspectRatio: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.aspectRatio = aspectRatio
        self.content = content
    }

    var body: some View {
        if let aspectRatio {
            Rectangle()
                .opacity(0)
                .overlay {
                    content()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .clipped()
        } else {
            content()
        }
    }
}

#Preview {
    struct ContentView: View {
        let url = "https://publicdomainq.net/images/201802/01s/publicdomainq-0018423cpl.jpg"

        func row(
            _ view: String,
            aspectRatio: CGFloat? = nil
        ) -> some View {
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("view: \(view)")
                        if let aspectRatio {
                            Text("aspectRatio: \(aspectRatio, specifier: "%.1f")")
                        } else {
                            Text("aspectRatio: nil")
                        }
                    }
                    Spacer()
                    AspectRatioContainer(aspectRatio: aspectRatio) {
                        if view == "image" {
                            AsyncImage(url: URL(string: url)) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                        } else if view == "text" {
                            Text(url)
                                .font(.system(size: 500))
                                .minimumScaleFactor(0.01)
                                .padding()
                        }
                    }
                    .background(.white)
                    .cornerRadius(5)
                }
                .frame(height: 100)
                Divider()
            }
        }

        var itemCollage: some View {
            VStack {
                HStack {
                    Text("item collage")

                    Spacer()

                    AspectRatioContainer(aspectRatio: 3/4) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                            ForEach(Array(sampleItems.prefix(7)), id: \.self) { item in
                                AspectRatioContainer(aspectRatio: 1) {
                                    AsyncImage(url: URL(string: item.imageURL!)) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .scaledToFit()
                                        }
                                    }
                                }
                            }
                        }
                        .scaledToFit()
                    }
                    .background(.white)
                    .cornerRadius(5)
                }
                .frame(height: 150)

                Divider()
            }
        }

        var body: some View {
            ScrollView {
                itemCollage
                row("text")
                row("image")
                row("text", aspectRatio: 1)
                row("image", aspectRatio: 1)
                row("text", aspectRatio: 2)
                row("image", aspectRatio: 2)
                row("text", aspectRatio: 1/2)
                row("image", aspectRatio: 1/2)
            }
            .padding()
            .background(.gray)
        }
    }

    return ContentView()
}
