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
    case applicatinoSupport(String)
    case documents(String)

    func getUiImage() async throws -> UIImage {
        switch self {
        case .uiImage(let image):
            return image
        case .url(let url):
            let image = try await downloadImage(url)
            return image
        case .applicatinoSupport(let path):
            let image = try LocalStorage.applicationSupport.loadImage(from: path)
            return image
        case .documents(let path):
            let image = try LocalStorage.documents.loadImage(from: path)
            return image
        }
    }
}
