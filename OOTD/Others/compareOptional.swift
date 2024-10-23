//
//  compareOptional.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/23.
//

import Foundation

func compareOptional<T: Comparable>(_ lhs: T?, _ rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
        return false // 両方が nil の場合、順序は変えない
    case (nil, _):
        return true // 左側が nil の場合、左が先
    case (_, nil):
        return false // 右側が nil の場合、右が先
    case (let lhsValue?, let rhsValue?):
        return lhsValue < rhsValue // 両方が非 nil の場合、通常の比較
    }
}
