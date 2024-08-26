//
//  AddButton.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/05.
//

import SwiftUI

struct AddButton: View {
    var action: () -> Void = {}

    var body: some View {
        Button {
            action()
        } label: {
            Rectangle()
                .opacity(0)
                .overlay {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fill)
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State var numOthers: Int = 3

        func otherContent(_ i: Int) -> some View {
            ZStack {
                Rectangle()
                    .stroke(.gray)
                    .foregroundColor(.black)
                VStack {
                    Text("\(i)")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fill)
        }

        var body: some View {
            // ScrollView の内側に GeometryReader を配置すると各セルが縦に潰れてしまう
            // https://qiita.com/macneko/items/bb90084ac4ec4eb33393
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 3), spacing: 5) {
                    AddButton {
                        if numOthers < 6 {
                            numOthers += 1
                        } else {
                            numOthers = 0
                        }
                    }
                    .border(.gray)

                    if numOthers >= 1 {
                        ForEach(1 ..< numOthers + 1, id: \.self) { i in
                            otherContent(i)
                        }
                    }
                }
            }
        }
    }

    return PreviewView()
}
