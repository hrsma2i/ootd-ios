//
//  CustomWebView.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/07/25.
//

import SwiftUI
import WebKit

private let logger = getLogger(#file)

struct CustomWebView: HashableView {
    let url: String
    let buttonText: String
    var onButtonTapped: (WKWebView) -> Void = { _ in }

    @StateObject private var manager = WebViewManager()
    @EnvironmentObject private var navigation: NavigationManager

    var webViewRepresentable: some View {
        WebViewRepresentable(url: URL(string: url)!) { webView in
            // WKKWebView の状態を監視し、この View の ProgressView に伝える
            manager.observeWebViewProperties(webView)

            // manager.recieveButtonTapped() が呼ばれたときに実行するコールバックをセット
            manager.setCancellable(
                webView,
                onButtonTapped: onButtonTapped
            )
        }
    }

    var isImportblePage: Bool {
        guard let currentUrl = manager.currentUrl?.absoluteString else {
            return false
        }

        return !currentUrl.hasPrefix("https://zozo.jp") || isZOZOImportablePage
    }

    var isZOZOImportablePage: Bool {
        guard let currentUrl = manager.currentUrl?.absoluteString else {
            return false
        }

        let goodsDetailPattern = #"https://zozo\.jp/sp/shop/[\w-]+/(goods-sale|goods)/\d+/"#

        return
            currentUrl.hasPrefix("https://zozo.jp/sp/_member/orderhistory/")
                || currentUrl.range(of: goodsDetailPattern, options: .regularExpression) != nil
    }

    var button: some View {
        RoundRectangleButton(text: "画像を選ぶ", fontSize: 20) {
            manager.recieveSaveButtonTapped()
        }
        .padding(7)
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            if manager.isLoading {
                ProgressView(value: manager.estimatedProgress).progressViewStyle(.linear)
            }

            webViewRepresentable

            Divider()

            if isImportblePage {
                button
            }
        }
        .navigationDestination(for: SelectWebImageScreen.self) { $0 }
    }
}

#Preview {
    DependencyInjector {
        CustomWebView(
            url: "https://zozo.jp/shop/barnssohostreet/goods-sale/41708194/?did=84288054",
            buttonText: "保存"
        )
    }
}