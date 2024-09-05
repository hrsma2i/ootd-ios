//
//  CustomWebView.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/07/25.
//

import SwiftUI
import WebKit

private let logger = getLogger(#file)

struct ImageImportWebView: HashableView {
    let url: String
    var onSelected: ([String], String) -> Void = { _, _ in }

    @StateObject private var manager = WebViewManager()
    @EnvironmentObject private var navigation: NavigationManager

    private func onButtonTapped(_ webView: WKWebView) {
        let currentUrl = webView.url!.absoluteString

        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { html, _ in

            guard let html = html as? String else { return }
            guard let doc = try? SwiftSoupDocumentWrapper(html, url: currentUrl) else { return }
            Task {
                guard let imageURLs = try? await doc.imageURLs() else { return }

                navigation.path.append(
                    SelectWebImageScreen(imageURLs: imageURLs) { urls in
                        onSelected(urls, currentUrl)
                    }
                )
            }
        }
    }

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

            button
        }
        .navigationDestination(for: SelectWebImageScreen.self) { $0 }
    }
}

#Preview {
    DependencyInjector {
        ImageImportWebView(
            url: "https://zozo.jp/shop/barnssohostreet/goods-sale/41708194/?did=84288054"
        )
    }
}
