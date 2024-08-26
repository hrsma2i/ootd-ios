//
//  RoundRectangleButton.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/15.
//

import SwiftUI

struct RoundRectangleButton: View {
    let text: String

    // MARK: - optional

    var systemName: String?
    var fontSize: CGFloat = 15
    var color: Color = .primary
    var radius: CGFloat?
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack {
                if let systemName {
                    Image(systemName: systemName)
                }
                Text(text)
            }
            .padding(.horizontal, 0.7 * fontSize)
            .padding(.vertical, 0.3 * fontSize)
            .font(.system(size: fontSize))
            .foregroundColor(.white)
            .background(color)
            .cornerRadius(radius ?? 1.0 * fontSize)
        }
    }
}

#Preview {
    VStack {
        ForEach(1 ..< 4) { i in
            RoundRectangleButton(
                text: Array(repeating: "保存", count: i).joined(),
                systemName: "checkmark",
                fontSize: CGFloat(i * 5 + 10)
            )
        }
    }
}
