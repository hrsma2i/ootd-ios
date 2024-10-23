//
//  OutfitGridTabDetail.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/10.
//

import SwiftUI

struct OutfitGridTabDetail: HashableView {
    let originalTab: OutfitGridTab
    var onDecided: (OutfitGridTab) -> Void

    @State private var tab: OutfitGridTab
    @State private var isAlertPresented: Bool = false
    @EnvironmentObject var navigation: NavigationManager

    init(tab: OutfitGridTab, onDecided: @escaping (OutfitGridTab) -> Void = { _ in }) {
        originalTab = tab
        self.tab = tab
        self.onDecided = onDecided
    }

    var hasChanges: Bool {
        tab != originalTab
    }

    func backWithAlertIfChanged() {
        if hasChanges {
            isAlertPresented = true
        } else {
            navigation.path.removeLast()
        }
    }

    var itemsRow: some View {
        VStack(spacing: 5) {
            HStack {
                Text("使用アイテム")
                    .padding(5)
                    .foregroundColor(Color(gray: 0.5))
                Spacer()
            }

            SelectedItemsGrid(
                items: $tab.filter.items
            )
        }
        .padding(5)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color(gray: 0.96))
        }
    }

    var backButton: some View {
        HStack {
            Button {
                backWithAlertIfChanged()
            } label: {
                HStack(spacing: 0) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }

            Spacer()
        }
        .padding(.horizontal)
    }

    var body: some View {
        VStack {
            backButton

            ScrollView {
                itemsRow
            }
            .padding(.horizontal)
        }
        .safeAreaInset(edge: .bottom) {
            if hasChanges {
                RoundRectangleButton(
                    text: "決定",
                    systemName: "checkmark",
                    fontSize: 20
                ) {
                    onDecided(tab)
                    navigation.path.removeLast()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .edgeSwipe { backWithAlertIfChanged() }
        .alert("破棄しますか？", isPresented: $isAlertPresented) {
            Button(role: .cancel) {} label: { Text("編集に戻る") }
            Button(role: .destructive) {
                navigation.path.removeLast()
            } label: { Text("破棄する") }
        } message: {
            Text("このまま戻ると、編集内容がすべて失われます。")
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State var tab = OutfitGridTab(
            name: "デフォルト",
            sort: .createdAtDescendant
        )

        var body: some View {
            DependencyInjector {
                OutfitGridTabDetail(
                    tab: tab
                )
            }
        }
    }

    return PreviewView()
}
