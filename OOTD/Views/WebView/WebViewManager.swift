//
//  WebViewManager.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/25.
//

import Combine
import Foundation
import WebKit

private let logger = getLogger(#file)

func cookiesKey(_ domain: URLDomain) -> String {
    return "\(domain.rawValue)-cookies"
}

final class WebViewManager: ObservableObject {
    static let shared = WebViewManager()

    private(set) var webView: WKWebView
    @Published private(set) var isLoading = false
    @Published private(set) var progress = 0.0
    // 更新は load から webView.url 経由でのみ行う
    @Published private(set) var url: URL = .init(string: "https://www.example.com")!

    private var cancellables: Set<AnyCancellable> = []

    private init() {
        webView = WKWebView()
        webView.load(URLRequest(url: url))

        for domain in URLDomain.allCases {
            let key = cookiesKey(domain)
            do {
                let cookies = try KeyChainHelper.shared.loadCookies(key: key)
                for cookie in cookies {
                    webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
                }
                logger.debug("load \(key) to WebView")
            } catch { continue }
        }

        webView.publisher(for: \.isLoading)
            .assign(to: &$isLoading)

        webView.publisher(for: \.estimatedProgress)
            .assign(to: &$progress)

        webView.publisher(for: \.url)
            .compactMap { $0 }
            .assign(to: &$url)

        $url
            .sink { [weak self] newUrl in
                logger.debug("url has changed to \(newUrl.absoluteString)")
                // save cookies
                if newUrl.host == URLDomain.zozo.rawValue {
                    Task { @MainActor [weak self] in
                        guard let cookies = await self?.webView.configuration.websiteDataStore.httpCookieStore.allCookies() else { return }

                        let key = cookiesKey(.zozo)
                        try KeyChainHelper.shared.saveCookies(key: key, cookies: cookies)
                    }
                }
            }
            .store(in: &cancellables)
    }

    func load(url: String) throws {
        guard let url = URL(string: url) else {
            throw "invalid url string: \(url)"
        }
        // reload
        webView.load(URLRequest(url: url))
    }
}
