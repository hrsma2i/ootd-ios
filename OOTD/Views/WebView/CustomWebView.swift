//
//  CustomWebView.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/07/25.
//

import SwiftUI
import WebKit

private let logger = getLogger(#file)

struct WebViewRepresentable: UIViewRepresentable {
    public func makeUIView(context: Context) -> WKWebView {
        return WebViewManager.shared.webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct CustomWebView: HashableView {
    let buttonText: String
    var onButtonTapped: (WKWebView) -> Void = { _ in }

    // シングルトンだが、 Published なプロパティの変化を検知して View を再描画する必要があるため StateObject として持たせている。
    @StateObject private var manager = WebViewManager.shared
    @EnvironmentObject private var navigation: NavigationManager

    init(url: String, buttonText: String, onButtonTapped: @escaping (WKWebView) -> Void = { _ in }) {
        do {
            try WebViewManager.shared.load(url: url)
        } catch {
            logger.warning("\(error)")
        }
        self.buttonText = buttonText
        self.onButtonTapped = onButtonTapped
    }

    var isImportblePage: Bool {
        let url = manager.url.absoluteString
        return !url.hasPrefix("https://zozo.jp") || isZOZOImportablePage
    }

    var isZOZOImportablePage: Bool {
        let url = manager.url.absoluteString
        let goodsDetailPattern = #"https://zozo\.jp/sp/shop/[\w-]+/(goods-sale|goods)/\d+/"#

        return
            url.hasPrefix("https://zozo.jp/sp/_member/orderhistory/")
                || url.range(of: goodsDetailPattern, options: .regularExpression) != nil
    }

    var button: some View {
        RoundRectangleButton(text: buttonText, fontSize: 20) {
            onButtonTapped(manager.webView)
        }
        .padding(7)
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            if manager.isLoading {
                ProgressView(value: manager.progress).progressViewStyle(.linear)
            }

            WebViewRepresentable()

            Divider()

            if isImportblePage {
                button
            }
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State var text: String = "<HTML>"
        @State var isPresent: Bool = false

        var body: some View {
            DependencyInjector {
                CustomWebView(
                    url: "https://zozo.jp/shop/barnssohostreet/goods-sale/41708194/?did=84288054",
                    buttonText: "HTMLを取得"
                ) { webView in
                    Task {
                        let text = try await webView.getHtml()
                        self.text = String(text.prefix(100))
                    }
                    // なぜか Task 内だと <HTML> のままになる
                    isPresent = true
                }
            }
            .sheet(isPresented: $isPresent) {
                Text(text)
            }
        }
    }

    return PreviewView()
}
