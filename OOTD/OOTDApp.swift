//
//  OOTDApp.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/26.
//

import SwiftUI

@main
struct OOTDApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    // to avoid initial delay
                    let _ = WebViewRepresentable.webView
                }
        }
    }
}
