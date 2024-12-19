//
//  OutfitDetail.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/02.
//

import SwiftUI

struct OutfitDetail: HashableView {
    @State var outfit: Outfit
    let mode: DetailMode
    @EnvironmentObject var outfitStore: OutfitStore
    @EnvironmentObject var navigation: NavigationManager
    @EnvironmentObject var snackbarStore: SnackbarStore

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
            Button {
                isImagePickerPresented = true
            } label: {
                VStack {
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 50))

                    Text("スナップ画像を設定")
                        .font(.system(size: 10))
                }
                .foregroundColor(.gray)
            }
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
                guard let originalImage = try await outfit.imageSource?.getUiImage(storage: outfitStore.storage) else { return }

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

    func section(@ViewBuilder content: @escaping () -> some View) -> some View {
        ItemDetail.section(content: content)
    }

    func propertyRow(_ key: String, _ value: String, action: (() -> Void)? = nil) -> some View {
        ItemDetail.propertyRow(key, value, action: action)
    }

    var body: some View {
        AdBannerContainer {
            ScrollView {
                // MARK: - バグ回避のための workaround

                // 本当はこの部分を snapImage といったメソッドに切り出したいが、メソッドとして呼び出すと OutfitGrid から遷移できずに固まる。
                // AspectRatioContainer と ZStack の相性が悪そう。
                VStack(spacing: 1) {
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
                .background(Color(gray: 0.95))

                VStack(spacing: 20) {
                    HStack {
                        EditableTagListView(tags: $outfit.tags)
                        Spacer()
                    }

                    section {
                        propertyRow("作成日時", outfit.createdAt?.toString() ?? "----/--/-- --:--:--")
                        Divider()
                        propertyRow("更新日時", outfit.updatedAt?.toString() ?? "----/--/-- --:--:--")
                    }
                }
                .padding(20)
            }
        }
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
                        Task { @MainActor in
                            defer {
                                navigation.path.removeLast()
                            }

                            await snackbarStore.notify(logger) {
                                switch mode {
                                case .create:
                                    try await outfitStore.create([outfit])
                                case .update:
                                    try await outfitStore.update([outfit], originalOutfits: [originalOutfit])
                                }
                            }
                        }
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
        @State private var isSheetPresented: Bool = false
        @State private var outfit: Outfit = outfits.values.first!
        static let outfits: [String: Outfit] = [
            "画像あり、日付なし": sampleOutfits.filter { $0.imageSource != nil }.first!,
            "画像あり、日付あり": sampleOutfits.filter { $0.imageSource != nil }.first!
                .copyWith(\.createdAt, value: Date())
                .copyWith(\.updatedAt, value: Date()),
            "画像なし": sampleOutfits.filter { $0.imageSource == nil }.first!,
        ]

        var body: some View {
            VStack {
                // ForEach + if がないと再描画されないため
                ForEach(PreviewView.outfits.keys.sorted(), id: \.self) { key in
                    if PreviewView.outfits[key] == outfit {
                        OutfitDetail(
                            outfit: outfit,
                            mode: .update
                        )
                    }
                }

                Button {
                    isSheetPresented = true
                } label: {
                    Text("その他のオプションの表示")
                }
                .padding(7)
            }
            .sheet(isPresented: $isSheetPresented) {
                Form {
                    ForEach(PreviewView.outfits.keys.sorted(), id: \.self) { key in
                        Button {
                            outfit = PreviewView.outfits[key]!
                            isSheetPresented = false
                        } label: {
                            Text(key)
                        }
                    }
                }
                .presentationDetents([.fraction(0.3)])
            }
        }
    }

    return DependencyInjector {
        PreviewView()
    }
}
