//
//  Date+initYMD.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/27.
//

import Foundation

extension Date {
    init(year: Int, month: Int, day: Int) {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        let calendar = Calendar.current
        self = calendar.date(from: components) ?? Date()
    }
}
