//
//  WebViewRepresentable.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/25.
//

import Foundation
import SwiftUI
import WebKit

private let logger = getLogger(#file)

public struct WebViewRepresentable: UIViewRepresentable {
    private let url: URL?
    private let configuration: WKWebViewConfiguration?
    private let beforeLoad: (WKWebView) -> Void

    static let webView = initWebView()

    private static func initWebView() -> WKWebView {
        let webView = WKWebView()
        let request = URLRequest(url: URL(string: "https://example.com")!)
        webView.load(request)

        for domain in URLDomain.allCases {
            let key = cookiesKey(domain)
            do {
                let cookies = try KeyChainHelper.shared.loadCookies(key: key)
                for cookie in cookies {
                    webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
                }
                logger.debug("load \(key) to WebView")
            } catch {}
        }

        logger.debug("init webView to avoid first delay")
        return webView
    }

    public init(
        url: URL? = nil,
        configuration: WKWebViewConfiguration? = nil,
        beforeLoad: @escaping (WKWebView) -> Void = { _ in }
    ) {
        self.url = url
        self.configuration = configuration
        self.beforeLoad = beforeLoad
    }

    public func makeUIView(context: Context) -> WKWebView {
        let _view = configuration == nil ? WebViewRepresentable.webView : WKWebView(frame: .zero, configuration: configuration!)
        beforeLoad(_view)
        _view.load(URLRequest(url: url!))
        return _view
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {}
}
