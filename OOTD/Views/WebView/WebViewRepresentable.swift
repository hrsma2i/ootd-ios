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
        let _view = configuration == nil ? WKWebView() : WKWebView(frame: .zero, configuration: configuration!)
        beforeLoad(_view)
        _view.load(URLRequest(url: url!))
        return _view
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {}
}
