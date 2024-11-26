//
//  String+matches.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/15.
//

import Foundation

extension String {
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }
}
