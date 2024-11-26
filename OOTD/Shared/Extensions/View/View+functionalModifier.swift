//
//  View+functionalModifier.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/08/08.
//

import Foundation
import SwiftUI

extension View {
    func functionalModifier<Content: View>(_ transform: @escaping (Self) -> Content) -> some View {
        transform(self)
    }
}
