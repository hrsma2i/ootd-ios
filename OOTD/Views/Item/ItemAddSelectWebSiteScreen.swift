//
//  ItemAddSelectWebSiteScreen.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/03.
//

import SwiftUI
import WebKit

private let logger = getLogger(#file)

struct ItemAddSelectWebSiteScreen: HashableView {
    @State private var searchQuery: String = ""
    @EnvironmentObject var navigation: NavigationManager
    @EnvironmentObject var itemStore: ItemStore

    func webView(_ url: String) -> CustomWebView {
        CustomWebView(
            url: url,
            buttonText: "画像を選ぶ",
            onButtonTapped: extractedItemsToSelectWebImageScreen
        )
    }

    func siteButton(_ name: String, url: String) -> some View {
        return Button {
            navigation.path.append(webView(url))
        } label: {
            Text(name)
                .font(.system(size: 20))
        }
    }

    private func extractedItemsToSelectWebImageScreen(_ webView: WKWebView) {
        guard let url = webView.url?.absoluteString else {
            logger.error("webView.url is nil")
            return
        }

        Task {
            do {
                let html = try await webView.getHtml()
                let doc = try Scraper(html, url: url)
                let items = try await doc.items()

                navigation.path.append(
                    SelectWebItemScreen(items: items)
                )
            } catch {
                logger.error("\(error)")
            }
        }
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    var body: some View {
        List {
            SearchBar(text: $searchQuery) { url in
                navigation.path.append(webView(url))
            }

            Section("以下からインポート") {
                siteButton("ZOZOTOWN", url: "https://zozo.jp/sp/_member/orderhistory/?ohid=&ohtype=2&baship=2&ohterm=\(currentYear)")
                siteButton("GU", url: "https://www.gu-global.com/jp/ja/member/purchase/history")
                siteButton("UNIQLO", url: "https://www.uniqlo.com/jp/ja/member/purchase/history")
                siteButton("Instagram", url: "https://www.instagram.com/")
            }
        }
        .navigationDestination(for: CustomWebView.self) { $0 }
        .navigationDestination(for: SelectWebItemScreen.self) { $0 }
    }
}

#Preview {
    DependencyInjector {
        ItemAddSelectWebSiteScreen()
    }
}
