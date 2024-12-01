// A
//  ScrollableTabView.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/16.
//

import Foundation
import SwiftUI

struct ScrollableTabView<Data: RandomAccessCollection, Content: View, ID: Hashable, Footer: View>: View {
    // https://zenn.dev/never_inc_dev/articles/303283ffaab541
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let title: (Data.Element) -> String
    let content: (Data.Element) -> Content
    let footer: () -> Footer

    let position: Position
    enum Position: String, Identifiable {
        case top,
             bottom

        var id: String { rawValue }
    }

    let onChange: ((ID?, ID?) -> Void)?

    init(position: Position = .bottom, _ data: Data, id: KeyPath<Data.Element, ID>, title: @escaping (Data.Element) -> String, content: @escaping (Data.Element) -> Content, footer: @escaping () -> Footer = { EmptyView() }, onChange: ((ID?, ID?) -> Void)? = nil) {
        self.position = position
        self.data = data
        self.id = id
        self.title = title
        self.content = content
        _selectedTabId = State(initialValue: data.first?[keyPath: id])
        self.footer = footer
        self.onChange = onChange
    }

    @State private var selectedTabId: ID?

    @Namespace private var tabNamespace

    var tabBar: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(data, id: id) { tab in
                        VStack(spacing: 0) {
                            Rectangle()
                                .frame(height: 4)
                                .foregroundColor(
                                    selectedTabId == tab[keyPath: id] ? .accent : .white
                                )
                                .matchedGeometryEffect(
                                    id: selectedTabId, in: tabNamespace, isSource: false
                                )

                            Button {
                                selectedTabId = tab[keyPath: id]
                            } label: {
                                Text(title(tab))
                                    .font(.system(size: 15))
                                    .bold()
                                    .foregroundStyle(
                                        selectedTabId == tab[keyPath: id] ? .accent : .gray
                                    )
                            }
                            .id(tab[keyPath: id])
                            .padding(10)
                            .matchedGeometryEffect(
                                id: tab[keyPath: id], in: tabNamespace, isSource: true
                            )
                        }
                    }
                }
            }
            .onChange(of: selectedTabId) { oldTabId, newTabId in
                if let newTabId, let index = data.firstIndex(where: { $0[keyPath: id] == newTabId }) {
                    withAnimation(.easeInOut) {
                        scrollProxy.scrollTo(
                            newTabId,
                            anchor: UnitPoint(
                                x: CGFloat(index as! Int) / CGFloat(data.count), y: 0
                            )
                        )
                    }
                }

                if let onChange {
                    onChange(oldTabId, newTabId)
                }
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    if position == .top {
                        tabBar
                        Divider()
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(data, id: id) {
                                content($0)
                                    .frame(width: geometry.size.width)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition(id: $selectedTabId)

                    if position == .bottom {
                        Divider()
                        tabBar
                    }
                }

                VStack(spacing: 0) {
                    footer()

                    Rectangle()
                        .opacity(0)
                        .frame(height: 44)
                }
            }
            .animation(.easeInOut, value: selectedTabId)
        }
    }
}

#Preview {
    ScrollableTabView(
        [
            "For you",
            "Trending",
            "News",
            "Sports",
            "Entertainment"
        ],
        id: \.self,
        title: { $0 }
    ) { element in
        VStack(alignment: .leading, spacing: 0) {
            Text(element)
                .font(.title)
                .padding()

            Divider()

            ScrollView {
                ZStack {
                    VStack {
                        ForEach(0 ..< 100, id: \.self) { num in
                            Text(num.description)
                                .padding()
                        }
                    }
                }
                .containerRelativeFrame(.horizontal)
            }
        }
        .padding(.bottom, 60)
    } footer: {
        Text("Footer")
            .padding()
            .foregroundColor(.white)
            .background(.accent)
            .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
            .padding(10)
    }
}
