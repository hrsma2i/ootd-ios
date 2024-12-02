//
//  Snackbar.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/02.
//

import SwiftUI

struct Snackbar: HashableView {
    let message: String
    let buttonText: String?
    var textColor = Color.white
    var buttonTextColor = Color(red: 163/255, green: 194/255, blue: 255/255)
    var backgroundColor = Color(gray: 0.3)
    var duration: TimeInterval = 5.0
    var cornerRadius: CGFloat = 5.0
    var action: () -> Void = {}

    var body: some View {
        HStack {
            Text(message)
                .foregroundColor(textColor)
            Spacer()

            if let buttonText {
                Button(action: action) {
                    Text(buttonText)
                        .bold()
                        .foregroundColor(buttonTextColor)
                }
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .shadow(radius: 5)
    }
}

#Preview {
    Snackbar(
        message: "保存しました",
        buttonText: "閉じる"
    )
    .padding()
}
