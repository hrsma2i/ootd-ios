//
//  WrappedLayout.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/08/02.
//
// https://stackoverflow.com/questions/58842453/swiftui-hstack-with-wrap

import SwiftUI

struct WrappedLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    var geometry: GeometryProxy?
    var spacing: CGFloat = 4
    @ViewBuilder var content: (Data.Element) -> Content

    var body: some View {
        if let geometry {
            generateContent(in: geometry)
        } else {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
    }

    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return VStack {
            ZStack(alignment: .topLeading) {
                ForEach(data, id: \.self) { element in
                    content(element)
                        .padding([.horizontal, .vertical], spacing)
                        .alignmentGuide(.leading, computeValue: { d in
                            if abs(width - d.width) > g.size.width {
                                width = 0
                                height -= d.height
                            }
                            let result = width
                            if element == data.last! {
                                width = 0 // last item
                            } else {
                                width -= d.width
                            }
                            return result
                        })
                        .alignmentGuide(.top, computeValue: { _ in
                            let result = height
                            if element == data.last! {
                                height = 0 // last item
                            }
                            return result
                        })
                }
            }
        }
    }
}

#Preview {
    GeometryReader { geometry in
        ScrollView {
            WrappedLayout(
                data: [
                    "Ninetendo",
                    "XBox",
                    "PlayStation",
                    "PlayStation 2",
                    "PlayStation 3",
                    "PlayStation 4 PlayStation 4 PlayStation 4",
                ],
                geometry: geometry
            ) { game in
                AspectRatioContainer {
                    Text(game)
                        .foregroundColor(.white)
                        .padding(7)
                }
                .background(.black)
                .cornerRadius(5)
            }

            Text("オーバーラップしないか確認用テキスト")
            Text("ScrollView 内で GeometryReader を使うと要素がオーバーラップしてしまうので、外から GeometryProxy を渡せるようにした")
        }
    }
}
