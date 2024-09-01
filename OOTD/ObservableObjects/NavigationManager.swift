//
//  NavigationManager.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/20.
//

import Foundation
import SwiftUI

class NavigationManager: ObservableObject {
    @Published var path = NavigationPath()
}
