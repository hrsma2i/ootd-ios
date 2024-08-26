//
//  UserInfoScreen.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/08/12.
//

import SwiftUI

struct UserInfoScreen: View {
    @EnvironmentObject var navigation: NavigationManager

    func row(_ key: String, _ value: String, action: (() -> Void)? = nil) -> some View {
        HStack {
            Text(key)
            Spacer()
            Text(value)
                .foregroundColor(.gray)

            if let action {
                Button {
                    action()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
    }

    var body: some View {
        Form {
            Section("開発者向け") {
                row("データソース", Config.DATA_SOURCE.rawValue)
                row("Build Config", Config.BUILD_CONFIG)
            }
        }
    }
}

#Preview {
    DependencyInjector {
        UserInfoScreen()
    }
}
