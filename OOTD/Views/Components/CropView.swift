//
//  ImageCropView.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/08.
//

import BrightroomEngine
import BrightroomUI
import SwiftUI



struct ImageCropView: HashableView {
    let editingStack: EditingStack
    var onCropped: (UIImage) -> Void

    init(uiImage: UIImage, onCropped: @escaping (UIImage) -> Void = { _ in }) {
        let imageProvider = ImageProvider(image: uiImage)
        editingStack = EditingStack(imageProvider: imageProvider)
        self.onCropped = onCropped
    }

    var body: some View {
        VStack {
            SwiftUICropView(
                editingStack: editingStack
            )

            RoundRectangleButton(text: "決定", fontSize: 20) {
                do {
                    let uiImage: UIImage = try editingStack.makeRenderer().render().uiImage
                    onCropped(uiImage)
                } catch {
                    logger.critical("\(error)")
                }
            }
        }
        .task {
            editingStack.start()
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State private var uiImage: UIImage?
        @EnvironmentObject private var navigation: NavigationManager

        var body: some View {
            VStack {
                Button {
                    Task {
                        do {
                            let image = try await downloadImage("https://gaijinpot.scdn3.secure.raxcdn.com/app/uploads/sites/6/2016/02/Mount-Fuji-New.jpg")
                            let view = ImageCropView(uiImage: image) {
                                uiImage = $0
                                navigation.path.removeLast()
                            }
                            navigation.path.append(view)
                        }
                    }
                } label: {
                    Text("download & crop image")
                }

                if let uiImage {
                    ImageCard(source: .uiImage(uiImage))
                }
            }
            .navigationDestination(for: ImageCropView.self) { $0 }
        }
    }

    return DependencyInjector {
        PreviewView()
    }
}
