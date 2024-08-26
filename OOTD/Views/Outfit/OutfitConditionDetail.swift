//
//  OutfitConditionDetail.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/10.
//

import SwiftUI

struct OutfitConditionDetail: HashableView {
    @EnvironmentObject var navigation: NavigationManager
    @Binding var condition: OutfitCondition

    func headline(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.title2)
                .bold()
            Spacer()
        }
    }

    var items: [Item] {
        condition.filter.items
    }

    var body: some View {
        GeometryReader { _ in
            ScrollView {
                headline("絞り込み")

                SelectedItemsGrid(
                    items: $condition.filter.items
                )

                Rectangle()
                    .fill(.gray)
                    .frame(height: 2)
                    .edgesIgnoringSafeArea(.horizontal)

                headline("並べ替え")
            }
            .navigationDestination(for: ItemGrid.self) { $0 }
            .padding()
            .navigationTitle("コーデ条件")
            .toolbarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    struct PreviewView: View {
//        @State var condition = OutfitCondition(
//            filter: OutfitFilter(
//                items: Array(sampleItems.shuffled().prefix(4))
//            )
//        )
        @State var condition = OutfitCondition()

        var body: some View {
            DependencyInjector {
                OutfitConditionDetail(
                    condition: $condition
                )
            }
        }
    }

    return PreviewView()
}
