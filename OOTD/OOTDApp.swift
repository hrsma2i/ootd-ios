//
//  OOTDApp.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/26.
//

import GoogleMobileAds
import SwiftUI

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        GADMobileAds.sharedInstance().start(completionHandler: nil)

        return true
    }
}

@main
struct OOTDApp: App {
    // To handle app delegate callbacks in an app that uses the SwiftUI lifecycle,
    // you must create an application delegate and attach it to your `App` struct
    // using `UIApplicationDelegateAdaptor`.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    // to avoid initial delay
                    let _ = WebViewManager.shared
                }
        }
    }
}
