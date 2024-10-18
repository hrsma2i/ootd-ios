//
//  OutfitDetail.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/02.
//

import SwiftUI

private let logger = getLogger(#file)

struct OutfitDetail: HashableView {
    @State var outfit: Outfit
    let mode: DetailMode
    @EnvironmentObject var outfitStore: OutfitStore
    @EnvironmentObject var navigation: NavigationManager

    // MARK: - private

    @State private var isAlertPresented = false
    @State private var isImagePickerPresented = false
    private let originalOutfit: Outfit

    init(outfit: Outfit, mode: DetailMode) {
        self.outfit = outfit
        self.originalOutfit = outfit
        self.mode = mode
    }

    var hasChanges: Bool {
        if mode == .create {
            return true
        } else {
            return outfit != originalOutfit
        }
    }

    var imageEmptyView: some View {
        AspectRatioContainer(aspectRatio: 1) {
            VStack {
                Image(systemName: "camera.circle.fill")
                    .font(.system(size: 50))
                Text("スナップ画像をアップロード")
                    .font(.system(size: 10))
            }
            .foregroundColor(.gray)
        }
    }

    var snapImage: some View {
        ZStack {
            // なぜか、そのまま Button の label としてラップすると画面が真っ白になってしまうので、しかたなく ZStack で透明な四角形のボタンを被せる
            if let imageSource = outfit.imageSource {
                ImageCard(
                    source: imageSource
                )
            } else {
                imageEmptyView
            }

            Button {
                isImagePickerPresented = true
            } label: {
                Rectangle()
                    .opacity(0)
            }
        }
    }

    var body: some View {
        ScrollView {
            snapImage

            SelectedItemsGrid(
                items: $outfit.items
            )
        }
        .background(Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255))
        .navigationTitle("コーデ詳細")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            if hasChanges {
                ToolbarItem(placement: .bottomBar) {
                    RoundRectangleButton(
                        text: "保存",
                        systemName: "checkmark",
                        fontSize: 20
                    ) {
                        Task {
                            do {
                                switch mode {
                                case .create:
                                    try await outfitStore.create([outfit])
                                case .update:
                                    try await outfitStore.update([outfit], originalOutfits: [originalOutfit])
                                }
                            } catch {
                                logger.error("\(error)")
                            }
                        }

                        navigation.path.removeLast()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if hasChanges {
                        isAlertPresented = true
                    } else {
                        navigation.path.removeLast()
                    }
                } label: {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left") // set image here
                            .fontWeight(.bold)
                        Text("Back")
                    }
                }
            }
        }
        .alert("破棄しますか？", isPresented: $isAlertPresented) {
            Button(role: .cancel) {} label: { Text("編集に戻る") }
            Button(role: .destructive) {
                navigation.path.removeLast()
            } label: { Text("破棄する") }
        } message: {
            Text("このまま戻ると、編集内容がすべて失われます。")
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(
                selectionLimit: 1
            ) { images in
                if images.isEmpty {
                    isImagePickerPresented = false
                    return
                }

                if let image = images.first {
                    outfit.imageSource = .uiImage(image)
                }

                isImagePickerPresented = false
            }
        }
        .navigationDestination(for: ItemGrid.self) { $0 }
    }
}

#Preview {
    struct PreviewView: View {
        @State private var isImageSourceNil: Bool = true

        var body: some View {
            VStack {
                if isImageSourceNil {
                    OutfitDetail(
                        outfit: sampleOutfits.filter { $0.imageSource == nil }.first!,
                        mode: .update
                    )
                } else {
                    OutfitDetail(
                        outfit: sampleOutfits.filter { $0.imageSource != nil }.first!,
                        mode: .update
                    )
                }

                Button {
                    isImageSourceNil.toggle()
                } label: {
                    Text("imageSource 有/無 切り替え")
                }
            }
        }
    }

    return DependencyInjector {
        PreviewView()
    }
}
