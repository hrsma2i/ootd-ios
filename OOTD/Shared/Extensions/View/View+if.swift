//
//  View+if.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/02.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
