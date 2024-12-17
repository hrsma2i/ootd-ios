//
//  String+toStringArray.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/17.
//

import Foundation

extension String {
    func toStringArray() throws -> [String] {
        guard let jsonData = data(using: .utf8) else {
            throw "Invalid JSON string: \(self)"
        }
        let array = try JSONDecoder().decode([String].self, from: jsonData)
        return array
    }
}
