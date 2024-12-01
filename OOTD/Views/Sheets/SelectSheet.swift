//
//  SelectSheet.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/23.
//

import SwiftUI

struct SelectSheet: HashableView {
    let options: [String]
    var currentValue: String?
    var onSelect: (String) -> Void = { _ in }

    var height: CGFloat {
        min(CGFloat(options.count) / 17 + 0.075, 1)
    }

    func row(_ option: String) -> some View {
        HStack {
            Button {
                onSelect(option)
            } label: {
                Text(option)
                    .if(currentValue == option) {
                        $0.bold()
                    }
            }
            Spacer()
        }
    }

    var body: some View {
        Form {
            Section {
                ForEach(options, id: \.self) { option in
                    row(option)
                }
            }
        }
        .presentationDetents([.fraction(height)])
    }
}

#Preview {
    struct PreviewView: View {
        @State private var isPresented = true
        @State private var numOptions = Int.random(in: 2 ... 15)

        var body: some View {
            Button("シート表示") {
                isPresented = true
                numOptions = Int.random(in: 2 ... 15)
            }
            .sheet(isPresented: $isPresented) {
                SelectSheet(
                    options: Array(0 ..< numOptions).map {
                        "選択肢\($0)"
                    },
                    currentValue: "選択肢1"
                )
            }
        }
    }

    return PreviewView()
}
