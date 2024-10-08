//
//  FirstRetailingPage.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/09.
//

import Foundation

protocol FirstRetailingPage {}

extension FirstRetailingPage {
    func removeAspectSuffix(_ imageUrl: String) -> String {
        imageUrl.replacingOccurrences(of: "_3x4", with: "")
    }
}
