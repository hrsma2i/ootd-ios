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

final class WebViewManager: ObservableObject {
    @Published var isLoading = false
    @Published var estimatedProgress = 0.0
    @Published var lastButtonTappedAt: Date? = nil
    @Published var currentUrl: URL? = nil
    var cancellable: Cancellable? = nil

    func observeWebViewProperties(_ webView: WKWebView) {
        // Combine の .publisher を使って WKWebView のプロパティを監視し、自身の @Published なプロパティにバインドする
        // なぜ DispatchQueue.main.async で囲むのか
        // https://stackoverflow.com/questions/77140328/how-to-avoid-swiftui-warnings-about-publishing-changes-from-within-view-updates
        DispatchQueue.main.async {
            webView.publisher(for: \.isLoading)
                .assign(to: &self.$isLoading)

            webView.publisher(for: \.estimatedProgress)
                .assign(to: &self.$estimatedProgress)

            webView.publisher(for: \.url)
                .assign(to: &self.$currentUrl)
        }
    }

    func recieveSaveButtonTapped() {
        lastButtonTappedAt = Date()
    }

    func setCancellable(_ webView: WKWebView, onButtonTapped: @escaping (WKWebView) -> Void) {
        // なぜ cancellable, subscriber を WebViewRepresentable.beforeLoad 内で定義しないか:
        // cancellable が makeUIView のスコープでしか生きられず、 lastSaveButtonTappedAt を更新してもコールバックが実行されないから

        // なぜ WebViewWithProgressBar ではなく ObservableObject に cancellable を持たせたか:
        // WebViewWithProgressBar が再描画されまくって、 cancellable もろとも破棄されるから、View より寿命の長い ObservableObject に持たせた。
        // なお、 WebViewManager を @StateObject ではなく @ObservedObject にしてしまうと、再描画のたびに WebViewManager も再生成され、同様のことが起きてしまうので注意。
        cancellable = $lastButtonTappedAt.sink { tappedAt in
            // 初回の発火を防ぐため、 Optional にして、 nil のときは発火しないようにした。
            if tappedAt != nil {
                onButtonTapped(webView)
            }
        }
    }
}
