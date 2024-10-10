//
//  String+extract.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/10.
//

import Foundation

extension String {
    func extract(_ pattern: String) throws -> String {
        let regex = try NSRegularExpression(pattern: pattern)
        
        let range = NSRange(startIndex ..< endIndex, in: self)
        
        guard let match = regex.firstMatch(in: self, options: [], range: range) else {
            throw "not match pattern \(pattern)"
        }
        
        guard let matchRange = Range(match.range(at: 1), in: self) else {
            throw "match range is invalid"
        }
        
        let extracted = String(self[matchRange])
        
        return extracted
    }
}
