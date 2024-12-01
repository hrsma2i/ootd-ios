//
//  String+errorDescription.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/24.
//

import Foundation

// https://zenn.dev/dena/articles/42a79c109fcdc6
extension String: LocalizedError {
    public var errorDescription: String? { self }
}
