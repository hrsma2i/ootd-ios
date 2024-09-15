//
//  Sequence+unique.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/15.
//

import Foundation

extension Sequence {
    func unique<T: Hashable>(by key: (Element) -> T) -> [Element] {
        // Array(Set()) だと順序が保証されないので
        var seen = [T]()
        return self.filter { element in
            let keyValue = key(element)
            if seen.contains(keyValue) {
                return false
            } else {
                seen.append(keyValue)
                return true
            }
        }
    }

    func unique() -> [Element] where Element: Hashable {
        return self.unique(by: { $0 })
    }
}
