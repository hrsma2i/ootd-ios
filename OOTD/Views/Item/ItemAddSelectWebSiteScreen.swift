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

                if let history = try generateEcPurchaseHisotry(html: html, url: url) {
                    let items = try await history.items()

                    navigation.path.append(
                        SelectWebItemScreen(items: items)
                    )
                } else if let detail = try await generateEcItemDetail(url: url) {
                    // TODO: 長いので別関数として切り分けたい
                    let imageUrls = try detail.imageUrls()
                    let name = try detail.name()
                    let colorOptions = try? detail.colors()
                    let brand = try? detail.brand()
                    let sizeOptions = try? detail.sizes()

                    navigation.path.append(
                        SelectWebImageScreen(
                            imageURLs: imageUrls,
                            limit: 1
                        ) { selected in
                            let imageUrl = selected.first!
                            let color = try? detail.selectColorFromImage(imageUrl)
                            var item = Item(
                                imageSource: .url(imageUrl),
                                option: .init(
                                    name: name,
                                    sourceUrl: url,
                                    originalColor: color,
                                    originalBrand: brand
                                )
                            )
                            Task {
                                item = try await item.copyWithPropertiesFromSourceUrl()

                                navigation.path.append(
                                    WebItemDetail(
                                        item: item,
                                        colorOptions: color == nil ? colorOptions : nil,
                                        sizeOptions: sizeOptions,
                                        onCreated: { _ in
                                            navigation.path = NavigationPath()
                                        }
                                    )
                                )
                            }
                        }
                    )
                }
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
        .navigationDestination(for: SelectWebImageScreen.self) { $0 }
        .navigationDestination(for: WebItemDetail.self) { $0 }
    }
}

#Preview {
    DependencyInjector {
        ItemAddSelectWebSiteScreen()
    }
}
