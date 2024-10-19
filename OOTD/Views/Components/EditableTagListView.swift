//
//  EditableTagListView.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/17.
//

import SwiftUI

struct EditableTagListView: View {
    @Binding var tags: [String]
    let spacing: CGFloat = 3

    @State private var editingText: String = ""

    var body: some View {
        FlowLayout {
            ForEach($tags, id: \.self) { tag in
                HStack {
                    Text(tag.wrappedValue)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Button {
                        tags = tags.filter { $0 != tag.wrappedValue }
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
            }

            TextField("タグを入力...", text: $editingText)
                .onSubmit {
                    tags.append(editingText)
                    editingText = ""
                }
                .frame(maxWidth: 100)
                .padding(spacing)
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
            "This so long text that is over the parent width. This so long text that is over the parent width. This so long text that is over the parent width.",
        ]

        var body: some View {
            GeometryReader { _ in
                ScrollView {
                    EditableTagListView(
                        tags: $tags
                    )
                }
            }
        }
    }

    return PreviewView()
}
