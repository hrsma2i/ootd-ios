//
//  Date+toString.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/27.
//

import Foundation

extension Date {
    func toString(hasTime: Bool = true) -> String {
        // https://qiita.com/rinov/items/bff12e9ea1251e895306
        let f = DateFormatter()
        if hasTime {
            f.timeStyle = .medium
        } else {
            f.timeStyle = .none
        }
        f.dateStyle = .medium
        f.locale = Locale(identifier: "ja_JP")
        return f.string(from: self)
    }
}
