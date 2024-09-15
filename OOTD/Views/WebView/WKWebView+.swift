//
//  WKWebView+.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/08/01.
//

import Foundation
import WebKit

extension WKWebView {
    func getCookie(filter: ((HTTPCookie) -> Bool)? = nil) async -> String {
        var cookies = await configuration.websiteDataStore.httpCookieStore.allCookies()

        if let filter {
            cookies = cookies.filter(filter)
        }

        let stringCookie = cookies.reduce("") { $0 + "\($1.name)=\($1.value);" }

        return stringCookie
    }

    func getHtml() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.evaluateJavaScript("document.documentElement.outerHTML.toString()") { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let html = result as? String {
                    continuation.resume(returning: html)
                } else {
                    continuation.resume(throwing: NSError(domain: "WKWebViewError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get HTML"]))
                }
            }
        }
    }
}
