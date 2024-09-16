//
//  SearchBar.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/16.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var onSubmit: (String) -> Void = { _ in }

    var body: some View {
        let color = Color(red: 100/255, green: 100/255, blue: 100/255)
        return HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(color)

            TextField("Google で検索 / URL を入力", text: $text)
                .onSubmit {
                    let url: String
                    if text.hasPrefix("https://") {
                        url = text
                    } else {
                        url = "https://www.google.com/search?q=\(text)"
                    }
                    onSubmit(url)
                }

            Button {
                text = ""
            } label: {
                Image(systemName: "multiply")
            }
        }
        .foregroundColor(color)
    }
}

#Preview {
    struct PreviewView: View {
        @State var text = ""

        var body: some View {
            SearchBar(text: $text)
                .padding(7)
        }
    }

    return PreviewView()
}
