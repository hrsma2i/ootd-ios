//
//  IconButton.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/18.
//

import SwiftUI

struct IconButton: View {
    let text: String
    let systemName: String
    var color: Color = .accent
    var fontSize: CGFloat = 10
    var iconSize: CGFloat?
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemName)
                    .font(.system(size: iconSize ?? fontSize * 1.5))

                Text(text)
                    .font(.system(size: fontSize))
                    .bold()
            }
            .bold()
            .foregroundColor(color)
        }
    }
}

#Preview {
    IconButton(
        text: "選択",
        systemName: "checkmark.square.fill",
        fontSize: 20
    )
}
