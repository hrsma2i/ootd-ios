//
//  RootView.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/20.
//

import SwiftUI



struct RootView: View {
    @StateObject private var itemStore = ItemStore(Config.DATA_SOURCE)
    @StateObject private var outfitStore = OutfitStore(Config.DATA_SOURCE)

    @StateObject private var navigation = NavigationManager()
    @StateObject private var snackbarStore = SnackbarStore()

    var body: some View {
        ZStack {
            NavigationStack(path: $navigation.path) {
                TabView {
                    OutfitGrid()
                        .tabItem {
                            VStack {
                                Text("コーデ")
                                Image("outfit")
                            }
                        }

                    ItemGrid()
                        .tabItem {
                            VStack {
                                Text("アイテム")
                                Image("t-shirt")
                            }
                        }

                    if Config.IS_DEBUG_MODE {
                        UserInfoScreen()
                            .tabItem {
                                Label("ユーザー", systemImage: "person.crop.circle")
                            }
                    }
                }
                .navigationDestination(for: ItemDetail.self) { $0 }
            }

            if itemStore.isWriting || outfitStore.isWriting {
                LoadingView()
            }
        }
        .snackbar(item: $snackbarStore.active) { $0 }
        .environmentObject(itemStore)
        .environmentObject(outfitStore)
        .environmentObject(navigation)
        .environmentObject(snackbarStore)
        .task {
            do {
                async let itemFetch: () = itemStore.fetch()
                async let outfitFetch: () = outfitStore.fetch()

                try await itemFetch
                try await outfitFetch

                outfitStore.joinItems(itemStore.items)
            } catch {
                logger.critical("\(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    RootView()
}
