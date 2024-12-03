//
//  LoadingView.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/01.
//

import SwiftUI

struct LoadingView: View {
    var text: String = "保存中..."

    var body: some View {
        ZStack {
            Color(gray: 0.7)
                .opacity(0.7)

            VStack(spacing: 15) {
                ProgressView()
                    .tint(.white)
                Text(text)
                    .foregroundColor(.init(gray: 0.9))
                    .bold()
            }
            .padding(40)
            .background(Color(gray: 0.1).opacity(0.7))
            .cornerRadius(10)
        }
    }
}

#Preview {
    LoadingView(text: "保存中...")
}
