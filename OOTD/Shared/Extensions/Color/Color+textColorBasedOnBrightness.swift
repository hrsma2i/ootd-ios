//
//  Color+textColorBasedOnBrightness.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/08/12.
//

import Foundation
import SwiftUI

extension Color {
    func brightness() -> CGFloat {
        // Convert SwiftUI Color to UIColor
        let uiColor = UIColor(self)

        // Get the brightness component from the UIColor
        var brightness: CGFloat = 0
        uiColor.getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)

        return brightness
    }

    func textColorBasedOnBrightness() -> Color {
        // Calculate brightness and determine text color
        return self.brightness() < 0.5 ? .white : .black
    }
}
