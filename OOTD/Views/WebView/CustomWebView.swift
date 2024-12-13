//
//  CustomWebView.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/07/25.
//

import SwiftUI
import WebKit

private let logger = CustomLogger(#file)

struct WebViewRepresentable: UIViewRepresentable {
    public func makeUIView(context: Context) -> WKWebView {
        return WebViewManager.shared.webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct CustomWebView: HashableView {
    let buttonText: String
    var onButtonTapped: (WKWebView) -> Void = { _ in }

    @State private var searchBarText: String
    // シングルトンだが、 Published なプロパティの変化を検知して View を再描画する必要があるため StateObject として持たせている。
    @StateObject private var manager = WebViewManager.shared
    @EnvironmentObject private var navigation: NavigationManager

    init(url: String, buttonText: String, onButtonTapped: @escaping (WKWebView) -> Void = { _ in }) {
        do {
            try WebViewManager.shared.load(url: url)
        } catch {
            logger.critical("\(error)")
        }
        self.buttonText = buttonText
        self.onButtonTapped = onButtonTapped
        self.searchBarText = url
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

    var searchBar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .frame(height: 50)
                .foregroundColor(Color(red: 250/255, green: 250/255, blue: 250/255))
                .shadow(color: Color(red: 200/255, green: 200/255, blue: 200/255), radius: 5)

            SearchBar(text: $searchBarText) { newUrl in
                do {
                    try manager.load(url: newUrl)
                } catch {
                    logger.critical("\(error)")
                }
            }
            .onChange(of: manager.url) {
                searchBarText = manager.url.absoluteString
            }
            .foregroundColor(Color(red: 130/255, green: 130/255, blue: 130/255))
            .padding(10)
        }
        .padding(7)
        .padding(.horizontal, 10)
    }

    var goBackButton: some View {
        Button {
            manager.webView.goBack()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 25))
        }
        .disabled(!manager.webView.canGoBack)
    }

    var goForwardButton: some View {
        Button {
            manager.webView.goForward()
        } label: {
            Image(systemName: "chevron.right")
                .font(.system(size: 25))
        }
        .disabled(!manager.webView.canGoForward)
    }

    var footer: some View {
        VStack(spacing: 0) {
            Divider()

            searchBar

            HStack(spacing: 50) {
                goBackButton

                goForwardButton

                button
                    .disabled(!isImportblePage)
            }
        }
        .background(.thinMaterial)
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            if manager.isLoading {
                ProgressView(value: manager.progress).progressViewStyle(.linear)
            }

            WebViewRepresentable()

            Divider()

            footer
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
