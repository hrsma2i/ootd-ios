//
//  ItemAddSelectWebSiteScreen.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/03.
//

import SwiftUI
import WebKit



struct ItemAddSelectWebSiteScreen: HashableView {
    @State private var searchQuery: String = ""
    @EnvironmentObject var navigation: NavigationManager
    @EnvironmentObject var itemStore: ItemStore

    func webView(_ url: String) -> CustomWebView {
        CustomWebView(
            url: url,
            buttonText: "画像を選ぶ",
            onButtonTapped: extractedItemsToSelectScreen
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

    private func extractedItemsToSelectScreen(_ webView: WKWebView) {
        guard let url = webView.url?.absoluteString else {
            logger.critical("webView.url is nil")
            return
        }

        Task {
            do {
                let html = try await webView.getHtml()
                let title = webView.title

                if let history = safeDo({ try generateEcPurchaseHisotry(html: html, url: url) }) {
                    try await createItemsFromEcPurchaseHisotry(history)
                } else if let detail = await safeDo({ try await generateEcItemDetail(url: url) }) {
                    try createItemFromEcDetail(detail)
                } else {
                    try createItemFromAnyWebPage(html: html, url: url, title: title)
                }
            } catch {
                logger.critical("\(error)")
            }
        }
    }

    private func createItemsFromEcPurchaseHisotry(_ history: EcPurchaseHistory) async throws {
        let items = try await history.items()

        navigation.path.append(
            SelectWebItemScreen(items: items)
        )
    }

    private func createItemFromEcDetail(_ detail: EcItemDetail) throws {
        let imageUrls = try detail.imageUrls()
        let name = try detail.name()

        let colorOptions = safeDo { try detail.colors() }
        let brand = safeDo { try detail.brand() }
        let sizeOptions = safeDo { try detail.sizes() }
        let price = safeDo { try detail.price() }

        navigation.path.append(
            SelectWebImageScreen(
                imageURLs: imageUrls,
                limit: 1
            ) { selected in
                let imageUrl = selected.first!
                let color = safeDo { try detail.selectColorFromImage(imageUrl) }
                var item = Item(
                    imageSource: .url(imageUrl),
                    option: .init(
                        name: name,
                        purchasedPrice: price,
                        sourceUrl: detail.url,
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

    private func createItemFromAnyWebPage(html: String, url: String, title: String?) throws {
        let scraper = try Scraper(html, url: url)
        let imageUrls = try scraper.imageUrls()

        navigation.path.append(
            SelectWebImageScreen(
                imageURLs: imageUrls,
                limit: 1
            ) { selected in
                let imageUrl = selected.first!
                let item = Item(
                    imageSource: .url(imageUrl),
                    option: .init(
                        name: title ?? "",
                        sourceUrl: url
                    )
                )
                Task {
                    navigation.path.append(
                        WebItemDetail(
                            item: item,
                            onCreated: { _ in
                                navigation.path = NavigationPath()
                            }
                        )
                    )
                }
            }
        )
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    var body: some View {
        AdBannerContainer {
            List {
                SearchBar(text: $searchQuery) { url in
                    navigation.path.append(webView(url))
                }

                Section("購入履歴からインポート") {
                    siteButton("ZOZOTOWN", url: "https://zozo.jp/sp/_member/orderhistory/?ohid=&ohtype=2&baship=2&ohterm=\(currentYear)")
                    siteButton("GU", url: "https://www.gu-global.com/jp/ja/member/purchase/history")
                    siteButton("UNIQLO", url: "https://www.uniqlo.com/jp/ja/member/purchase/history")
                }
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
