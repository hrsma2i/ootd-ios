//
//  ItemAddSelectWebSiteScreen.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/03.
//

import SwiftUI

struct ItemAddSelectWebSiteScreen: HashableView {
    @EnvironmentObject var navigation: NavigationManager
    @EnvironmentObject var itemStore: ItemStore

    func siteButton(_ name: String, url: String) -> some View {
        return Button {
            navigation.path.append(
                ImageImportWebView(url: url) { imageUrls, _ in
                    let items = imageUrls.map { Item(imageURL: $0) }
                    navigation.path = NavigationPath()
                    navigation.path.append(
                        ItemDetail(items: items)
                    )
                }
            )
        } label: {
            Text(name)
                .font(.system(size: 20))
        }
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    var body: some View {
        List {
            Section("インポート元") {
                siteButton("ZOZOTOWN", url: "https://zozo.jp/sp/_member/orderhistory/?ohid=&ohtype=2&baship=2&ohterm=\(currentYear)")
                siteButton("GU", url: "https://www.gu-global.com/jp/ja/member/purchase/history")
                siteButton("UNIQLO", url: "https://www.uniqlo.com/jp/ja/member/purchase/history")
                siteButton("Instagram", url: "https://www.instagram.com/")
            }
        }
        .navigationDestination(for: ImageImportWebView.self) { $0 }
        .navigationDestination(for: ItemDetail.self) { $0 }
    }
}

#Preview {
    DependencyInjector {
        ItemAddSelectWebSiteScreen()
    }
}
