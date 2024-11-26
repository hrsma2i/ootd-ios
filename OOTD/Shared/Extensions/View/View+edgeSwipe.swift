//
//  View+edgeSwipe.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/17.
//

import Foundation
import SwiftUI

struct EdgeSwipe: ViewModifier {
    // https://qiita.com/kaito-seita/items/083831ff99b69a6af207
    var onSwiped: () -> Void

    private let edgeWidth: Double = 300
    private let baseDragWidth: Double = 50

    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture().onChanged { value in
                    if value.startLocation.x < self.edgeWidth, value.translation.width > self.baseDragWidth {
                        self.onSwiped()
                    }
                }
            )
    }
}

extension View {
    func edgeSwipe(onSwiped: @escaping () -> Void) -> some View {
        self.modifier(EdgeSwipe(onSwiped: onSwiped))
    }
}
