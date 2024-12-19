//
//  ImageSource.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/19.
//

import Foundation
import UIKit

enum ImageSource: Hashable {
    case uiImage(UIImage)
    case url(String)
    case storagePath(String)

    func getUiImage(storage: FileStorage?) async throws -> UIImage {
        switch self {
        case .uiImage(let image):
            return image
        case .url(let url):
            let image = try await downloadImage(url)
            return image
        case .storagePath(let path):
            guard let storage else {
                throw "failed to load image from storage because storage is nil"
            }

            let image = try await storage.loadImage(from: path)
            return image
        }
    }
}
