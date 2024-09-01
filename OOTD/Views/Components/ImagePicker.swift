//
//  ImagePicker.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/01.
//

import PhotosUI
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    typealias ImageSelectionHandler = ([UIImage]) -> Void

    var selectionLimit = 0 // 0 は制限なしを意味します
    let onImagesSelected: ImageSelectionHandler

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = selectionLimit
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_: PHPickerViewController, context _: Context) {
        // 更新処理はここでは行いません
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            var selectedImages: [UIImage] = []

            let group = DispatchGroup()

            for result in results {
                group.enter()

                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                        defer {
                            group.leave()
                        }

                        if let image = image as? UIImage {
                            selectedImages.append(image)
                        }
                    }
                } else {
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                self.parent.onImagesSelected(selectedImages)
            }
        }
    }
}
