//
//  EditableTagListView.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/17.
//

import SwiftUI

struct EditableTagListView: View {
    @Binding var tags: [String]
    let geometry: GeometryProxy
    let spacing: CGFloat = 3

    @State private var editingText: String = ""

    var body: some View {
        WrappedLayout(
            data: Array(0 ... tags.count),
            geometry: geometry,
            spacing: spacing
        ) { index in
            if index == tags.count {
                TextField("タグを入力...", text: $editingText)
                    .onSubmit {
                        tags.append(editingText)
                        editingText = ""
                    }
                    .frame(maxWidth: 100)
                    .padding(spacing)
            } else {
//                AspectRatioContainer {
                HStack {
                    Text(tags[index])
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Button {
                        tags.remove(at: index)
                    } label: {
                        Image(systemName: "multiply")
                    }
                }
                .foregroundColor(.accent)
                .padding(spacing)
                .padding(.horizontal, 10)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke()
                        .foregroundColor(.accent)
                }
//                }
//                .background(.accent)
//                .cornerRadius(20)
            }
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State private var tags: [String] = [
            "Ninetendo",
            "XBox",
            "PlayStation",
            "PlayStation 2",
            "PlayStation 3",
            "PlayStation 4 PlayStation 4 PlayStation 4",
        ]

        var body: some View {
            GeometryReader { geometry in
                ScrollView {
                    EditableTagListView(
                        tags: $tags,
                        geometry: geometry
                    )
                }
            }
        }
    }

    return PreviewView()
}
