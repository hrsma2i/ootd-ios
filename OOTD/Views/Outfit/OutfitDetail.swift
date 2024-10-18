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
    @State private var isImageEditDialogPresented = false
    private let originalOutfit: Outfit

    init(outfit: Outfit, mode: DetailMode) {
        self.outfit = outfit
        self.originalOutfit = outfit
        self.mode = mode
    }

    var hasChanges: Bool {
        // Item では画像が必須なので .create 時は必ず保存ボタンを表示したいが、 Outfit の場合はすべて空のときは保存ボタンを表示させたくないため .create / .update で表示条件を分けない
        return outfit != originalOutfit
    }

    var imageEmptyView: some View {
        AspectRatioContainer(aspectRatio: 1) {
            VStack {
                Image(systemName: "camera.circle.fill")
                    .font(.system(size: 50))

                Text("スナップ画像を設定")
                    .font(.system(size: 10))
            }
            .foregroundColor(.gray)
        }
    }

    var editImageButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()

                Button {
                    isImageEditDialogPresented = true
                } label: {
                    let height: CGFloat = 40
                    let fontSize: CGFloat = 23
                    let padding: CGFloat = 10
                    return Circle().foregroundColor(.black).opacity(0.5).frame(height: height)
                        .overlay {
                            Image(systemName: "pencil")
                                .foregroundColor(.white)
                                .font(.system(size: fontSize))
                        }
                        .padding(padding)
                }
            }
        }
    }

    var cropImageButton: some View {
        Button("切り抜く") {
            Task {
                guard let originalImage = try await outfit.imageSource?.getUiImage() else { return }

                navigation.path.append(
                    ImageCropView(uiImage: originalImage) { editedImage in
                        self.outfit = outfit
                            .copyWith(\.imageSource, value: .uiImage(editedImage))
                            .copyWith(\.thumbnailSource, value: .uiImage(editedImage))

                        navigation.path.removeLast()
                    }
                )
            }
        }
    }

    var changeImageButton: some View {
        Button("画像を変更する") {
            isImagePickerPresented = true
        }
    }

    func backWithAlertIfChanged() {
        if hasChanges {
            isAlertPresented = true
        } else {
            navigation.path.removeLast()
        }
    }

    @ViewBuilder
    func backButton(isEmpty: Bool = false) -> some View {
        if isEmpty {
            VStack {
                HStack {
                    Button {
                        backWithAlertIfChanged()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                    .padding(20)

                    Spacer()
                }
                Spacer()
            }
        } else {
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.15), Color.clear]),
                    startPoint: .init(x: 0.0, y: 0.0),
                    endPoint: .init(x: 0.0, y: 0.4)
                )
                .allowsHitTesting(false)

                Button {
                    backWithAlertIfChanged()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(20)
            }
        }
    }

    var body: some View {
        ScrollView {
            // MARK: - バグ回避のための workaround

            // 本当はこの部分を snapImage といったメソッドに切り出したいが、メソッドとして呼び出すと OutfitGrid から遷移できずに固まる。
            // AspectRatioContainer と ZStack の相性が悪そう。
            ZStack {
                if let imageSource = outfit.imageSource {
                    // 本当はこっちだけ ZStack でくくりたいが、そうすると OutfitGrid から遷移できずに固まる。
                    ImageCard(
                        source: imageSource
                    )

                    backButton()

                    editImageButton
                } else {
                    imageEmptyView

                    backButton(isEmpty: true)
                }
            }

            // MARK: バグ回避のための workaround -

            SelectedItemsGrid(
                items: $outfit.items
            )
        }
        .background(Color(red: 240 / 255, green: 240 / 255, blue: 240 / 255))
        .navigationBarHidden(true)
        .edgeSwipe { backWithAlertIfChanged() }
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
        .navigationDestination(for: ImageCropView.self) { $0 }
        .confirmationDialog("画像を編集する", isPresented: $isImageEditDialogPresented, titleVisibility: .visible) {
            cropImageButton
            changeImageButton
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State private var isImageSourceNil: Bool = false

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
