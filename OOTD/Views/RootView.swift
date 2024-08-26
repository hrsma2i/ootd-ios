//
//  RootView.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/20.
//

import SwiftUI

private let logger = getLogger(#file)

struct RootView: View {
    @StateObject private var itemStore = ItemStore(Config.DATA_SOURCE)
    @StateObject private var outfitStore = OutfitStore(Config.DATA_SOURCE)

    @StateObject private var navigation = NavigationManager()

    var body: some View {
        NavigationStack(path: $navigation.path) {
            TabView {
                OutfitGrid()
                    .tabItem {
                        Label("コーデ", systemImage: "square.split.2x2.fill")
                    }

                ItemGrid()
                    .tabItem {
                        Label("アイテム", systemImage: "list.bullet")
                    }

                UserInfoScreen()
                    .tabItem {
                        Label("ユーザー", systemImage: "person.crop.circle")
                    }
            }
            .navigationDestination(for: ItemDetail.self) { $0 }
        }
        .environmentObject(itemStore)
        .environmentObject(outfitStore)
        .environmentObject(navigation)
        .task {
            do {
                async let itemFetch: () = itemStore.fetch()
                async let outfitFetch: () = outfitStore.fetch()

                try await itemFetch
                try await outfitFetch

                outfitStore.joinItems(itemStore.items)
            } catch {
                logger.error("\(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    RootView()
}
