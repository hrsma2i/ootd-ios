//
//  CategorySelectSheet.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/17.
//

import SwiftUI

struct CategorySelectSheet: HashableView {
    var allowUncategorized: Bool = false
    var allowNil: Bool = false
    var onSelect: (Category?) -> Void = { _ in }

    var categories: [Category] {
        if allowUncategorized {
            Category.allCases
        } else {
            Category.allCasesWithoutUncategorized
        }
    }

    func categoryRow(_ category: Category?) -> some View {
        HStack {
            Button {
                onSelect(category)
            } label: {
                Text(category?.rawValue ?? "指定なし")
            }
            Spacer()
        }
    }

    var body: some View {
        VStack {
            Text("カテゴリー選択")
                .font(.headline)
                .padding(.bottom)

            VStack(alignment: .leading, spacing: 20) {
                ForEach(categories, id: \.self) { category in
                    categoryRow(category)
                }

                if allowNil {
                    categoryRow(nil)
                }

                Spacer()
            }
        }
        .padding()
    }
}

#Preview {
    struct PreviewView: View {
        @State private var isPresented = true
        @State private var allowUncategorized = false
        @State private var allowNil = false

        var body: some View {
            VStack(spacing: 20) {
                Button {
                    isPresented = true
                } label: {
                    Text("カテゴリー選択")
                }

                Button {
                    allowUncategorized = !allowUncategorized
                } label: {
                    Text(allowUncategorized ? "未分類を除く" : "未分類を含める")
                }

                Button {
                    allowNil = !allowNil
                } label: {
                    Text(allowNil ? "指定なしを除く" : "指定なしを含める")
                }
            }
            .sheet(isPresented: $isPresented) {
                CategorySelectSheet(
                    allowUncategorized: allowUncategorized,
                    allowNil: allowNil
                ) { _ in
                    isPresented = false
                }
            }
        }
    }

    return PreviewView()
}
