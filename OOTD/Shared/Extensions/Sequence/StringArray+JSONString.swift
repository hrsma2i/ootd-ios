//
//  StringArray+JSONString.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/12/17.
//

import Foundation

import Foundation

extension Array where Element == String {
    func toJSONString() throws -> String {
        let jsonData = try JSONEncoder().encode(self)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw "Failed to encode [String] to JSON string"
        }
        return jsonString
    }
}
