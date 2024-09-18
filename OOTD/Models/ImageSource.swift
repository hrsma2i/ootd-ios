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
    case localPath(String)
}
