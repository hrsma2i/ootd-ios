//
//  HashableView.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/08/26.
//

import Foundation
import SwiftUI

protocol HashableView: View, Hashable {
    var id: UUID { get }
}

extension HashableView {
    var id: UUID {
        UUID()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
