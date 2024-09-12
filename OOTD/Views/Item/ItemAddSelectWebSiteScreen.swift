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
                    navigation.path.append(webView(url))
                }

            Button {
                searchQuery = ""
            } label: {
                Image(systemName: "multiply")
                    .foregroundColor(color)
            }
        }
    }

    private func extractedItemsToSelectWebImageScreen(_ webView: WKWebView) {
        // TODO: manager の方から取得できるならそれでいい
        guard let currentUrl = webView.url?.absoluteString else {
            logger.error("webView.url is nil")
            return
        }

        // TODO: await にしてネストを浅くする
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { html, _ in

            guard let html = html as? String else { return }
            guard let doc = try? SwiftSoupDocumentWrapper(html, url: currentUrl) else { return }
            Task {
                do {
                    let urls = try await doc.imageAndSourceUrls()

                    navigation.path.append(
                        SelectWebImageScreen(
                            imageURLs: urls.map(\.imageUrl)
                        ) { selectedImageUrls in
                            let selectedUrls = urls.filter {
                                selectedImageUrls.contains($0.imageUrl)
                            }
                            selectedItemsToItemDetail(selectedUrls)
                        }
                    )
                } catch {
                    logger.error("\(error)")
                }
            }
        }
    }

    private func selectedItemsToItemDetail(_ urls: [(imageUrl: String, sourceUrl: String)]) {
        let items = urls.compactMap {
            Item(imageURL: $0.imageUrl, sourceUrl: $0.sourceUrl)
        }

        navigation.path = NavigationPath()
        navigation.path.append(
            ItemDetail(items: items)
        )
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
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
        .navigationDestination(for: CustomWebView.self) { $0 }
        .navigationDestination(for: ItemDetail.self) { $0 }
    }
}

#Preview {
    DependencyInjector {
        ItemAddSelectWebSiteScreen()
    }
}
