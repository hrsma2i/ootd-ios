//
//  RoundRectangleButton.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/07/15.
//

import SwiftUI

struct RoundRectangleButton: View {
    let text: String

    // MARK: - optional

    var systemName: String?
    var fontSize: CGFloat = 15
    var color: Color = .accentColor
    var radius: CGFloat?
    var fill: Bool = true
    var action: () -> Void = {}

    var label: some View {
        HStack {
            if let systemName {
                Image(systemName: systemName)
            }
            Text(text)
        }
        .padding(.horizontal, 0.7 * fontSize)
        .padding(.vertical, 0.3 * fontSize)
        .font(.system(size: fontSize))
    }

    var body: some View {
        Button(action: action) {
            if fill {
                label
                    .foregroundColor(.white)
                    .background(color)
                    .cornerRadius(radius ?? 1.0 * fontSize)
            } else {
                label
                    .foregroundColor(color)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius ?? 1.0 * fontSize)
                            .stroke(color, lineWidth: 2)
                    }
            }
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

        RoundRectangleButton(
            text: "塗りつぶし無し",
            fontSize: 25,
            fill: false
        )
    }
}
