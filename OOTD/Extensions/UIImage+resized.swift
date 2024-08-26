//
//  UIImage+resized.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/21.
//

import Foundation
import UIKit

enum ImageResizingError: Error {
    case resizingFailed
}

extension UIImage {
    func resized(to longerSide: CGFloat) throws -> UIImage {
        let aspectRatio = size.width / size.height
        let newSize: CGSize

        if aspectRatio > 1 {
            // 横長の画像
            newSize = CGSize(width: longerSide, height: longerSide / aspectRatio)
        } else {
            // 縦長の画像
            newSize = CGSize(width: longerSide * aspectRatio, height: longerSide)
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: newSize))

        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let finalImage = resizedImage else {
            throw ImageResizingError.resizingFailed
        }

        return finalImage
    }
}
