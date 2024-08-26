//
//  DependencyInjector.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/20.
//

import SwiftUI

struct DependencyInjector<Content: View>: View {
    let content: () -> Content

    @StateObject private var itemStore = ItemStore()
    @StateObject private var outfitStore = OutfitStore()
    @StateObject private var navigation = NavigationManager()

    var body: some View {
        NavigationStack(path: $navigation.path) {
            content()
        }
        .environmentObject(itemStore)
        .environmentObject(outfitStore)
        .environmentObject(navigation)
        .task {
            Task {
                do {
                    try await itemStore.fetch()
                    try await outfitStore.fetch()
                }
            }
        }
    }
}

#Preview {
    DependencyInjector {
        ItemGrid()
    }
}
