//
//  WKWebView+getCookie.swift
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
}
