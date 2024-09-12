//
//  ItemAddSelectWebSiteScreen.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/03.
//

import SwiftUI

struct ItemAddSelectWebSiteScreen: HashableView {
    @State private var searchQuery: String = ""
    @EnvironmentObject var navigation: NavigationManager
    @EnvironmentObject var itemStore: ItemStore

    func siteButton(_ name: String, url: String) -> some View {
        return Button {
            navigation.path.append(
                ImageImportWebView(url: url, onSelected: passImagesToItemDetail)
            )
        } label: {
            Text(name)
                .font(.system(size: 20))
        }
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    private func passImagesToItemDetail(urls: [(imageUrl: String, sourceUrl: String)]) {
        let items = urls.map { Item(imageURL: $0.imageUrl, sourceUrl: $0.sourceUrl) }
        navigation.path = NavigationPath()
        navigation.path.append(
            ItemDetail(items: items)
        )
    }

    private var searchBar: some View {
        let color = Color(red: 200/255, green: 200/255, blue: 200/255)
        return HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(color)

            TextField("Google で検索 / URL を入力", text: $searchQuery)
                .onSubmit {
                    let url: String
                    if searchQuery.hasPrefix("https://") {
                        url = searchQuery
                    } else {
                        url = "https://www.google.com/search?q=\(searchQuery)"
                    }
                    navigation.path.append(
                        ImageImportWebView(url: url, onSelected: passImagesToItemDetail)
                    )
                }

            Button {
                searchQuery = ""
            } label: {
                Image(systemName: "multiply")
                    .foregroundColor(color)
            }
        }
    }

    var body: some View {
        List {
            searchBar

            Section("以下からインポート") {
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
