//
//  RootScreen.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/26.
//

import SwiftUI

struct RootScreen: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    RootScreen()
}
