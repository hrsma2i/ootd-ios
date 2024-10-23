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

    var categories: [Category?] {
        var categories: [Category?]

        if allowUncategorized {
            categories = Category.allCases
        } else {
            categories = Category.allCasesWithoutUncategorized
        }

        if allowNil {
            categories.append(nil)
        }

        return categories
    }

    var height: CGFloat {
        CGFloat(categories.count) / 15
    }

    func categoryRow(_ category: Category?) -> some View {
        HStack {
            Button {
                onSelect(category)
            } label: {
                Text(category?.rawValue ?? "すべて")
            }
            Spacer()
        }
    }

    var body: some View {
        Form {
            Section("カテゴリー選択") {
                ForEach(categories, id: \.self) { category in
                    categoryRow(category)
                }
            }
        }
        .presentationDetents([.fraction(height)])
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
