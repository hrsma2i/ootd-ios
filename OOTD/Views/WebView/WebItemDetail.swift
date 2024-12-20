//
//  WebItemDetail.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/28.
//

import SwiftUI

struct WebItemDetail: HashableView {
    @State var item: Item
    var colorOptions: [String]?
    var sizeOptions: [String]?
    var onCreated: (Item) -> Void = { _ in }
    var onBacked: (Item) -> Void = { _ in }

    @State private var isImageEditDialogPresented: Bool = false
    @State private var imageUrlOptions: [String] = []
    @State private var activeSheet: ActiveSheet? = nil
    enum ActiveSheet: Int, Identifiable {
        case selectColor
        case selectSize

        var id: Int {
            rawValue
        }
    }

    @EnvironmentObject var navigation: NavigationManager
    @EnvironmentObject var itemStore: ItemStore
    @EnvironmentObject var snackbarStore: SnackbarStore

    func itemCard(_ item: Item) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ItemCard(
                item: item,
                padding: 0,
                aspectRatio: nil
            )
        }
    }

    var editImageButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    Task {
                        isImageEditDialogPresented = true
                    }
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
                let originalImage = try await item.imageSource.getUiImage(storage: itemStore.storage)

                navigation.path.append(
                    ImageCropView(uiImage: originalImage) { editedImage in
                        self.item = item
                            .copyWith(\.imageSource, value: .uiImage(editedImage))
                            .copyWith(\.thumbnailSource, value: .uiImage(editedImage))

                        navigation.path.removeLast()
                    }
                )
            }
        }
    }

    var changeImageButton: some View {
        Button("他の画像を選ぶ") {
            navigation.path.append(
                SelectWebImageScreen(
                    imageURLs: imageUrlOptions,
                    limit: 1
                ) { selected in
                    navigation.path.removeLast()

                    guard selected.count == 1 else {
                        fatalError("selected.count != 1")
                    }

                    let imageUrl = selected.first!

                    item = item.copyWith(\.imageSource, value: .url(imageUrl))
                        .copyWith(\.thumbnailSource, value: .url(imageUrl))
                }
            )
        }
    }

    func onBacked_() {
        onBacked(item)
        navigation.path.removeLast()
    }

    var backButton: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.15), Color.clear]),
                startPoint: .init(x: 0.0, y: 0.0),
                endPoint: .init(x: 0.0, y: 0.4)
            )
            .allowsHitTesting(false)

            Button {
                onBacked_()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(20)
        }
    }

    var imageRow: some View {
        ZStack {
            itemCard(item)

            backButton

            editImageButton
        }
    }

    func propertyRow(_ key: String, _ value: String, action: (() -> Void)? = nil) -> some View {
        ItemDetail.propertyRow(key, value, action: action)
    }

    func section(@ViewBuilder content: @escaping () -> some View) -> some View {
        ItemDetail.section(content: content)
    }

    var saveButton: some View {
        VStack {
            Spacer()
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
                        try await itemStore.create([item])
                        onCreated(item)
                    }
                }
            }
        }
    }

    @ViewBuilder
    var colorRow: some View {
        let title = "カラー"
        if colorOptions != nil {
            propertyRow(title, item.originalColor ?? "<選ぶ>") {
                activeSheet = .selectColor
            }
        } else {
            propertyRow(title, item.originalColor ?? "-")
        }
    }

    @ViewBuilder
    var sizeRow: some View {
        let title = "サイズ"
        if colorOptions != nil {
            propertyRow(title, item.originalSize ?? "<選ぶ>") {
                activeSheet = .selectSize
            }
        } else {
            propertyRow(title, item.originalColor ?? "-")
        }
    }

    @ViewBuilder
    func selectableRow(_ key: String, _ value: String?, _ options: [String]?, _ sheet: ActiveSheet) -> some View {
        if options != nil {
            propertyRow(key, value ?? "<選ぶ>") {
                activeSheet = sheet
            }
        } else {
            propertyRow(key, value ?? "-")
        }
    }

    func selectSheet(_ options: [String], key: WritableKeyPath<Item, String?>) -> some View {
        SelectSheet(
            options: options
        ) { value in
            item = item.copyWith(key, value: value)
            activeSheet = nil
        }
    }

    var body: some View {
        AdBannerContainer {
            ZStack(alignment: .bottom) {
                ScrollView {
                    imageRow

                    VStack(spacing: 20) {
                        ItemDetail.NameRow(text: item.name)

                        section {
                            propertyRow("カテゴリー", item.originalCategoryPath?.joined(separator: " > ") ?? "-")
                            Divider()
                            selectableRow("カラー", item.originalColor, colorOptions, .selectColor)
                            Divider()
                            propertyRow("ブランド", item.originalBrand ?? "-")
                            Divider()
                            selectableRow("サイズ", item.originalSize, sizeOptions, .selectSize)
                            Divider()
                            propertyRow("URL", item.sourceUrl ?? "-")
                            Divider()
                            ItemDetail.priceRow(item)
                            Divider()
                            propertyRow("購入日", item.purchasedOn?.toString(hasTime: false) ?? "----/--/--")
                            Divider()
                            ItemDetail.descriptionRow(item.originalDescription ?? "")
                        }
                    }.padding(20)
                }

                saveButton
            }
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) {
                switch $0 {
                case .selectColor:
                    selectSheet(colorOptions!, key: \.originalColor)
                case .selectSize:
                    selectSheet(sizeOptions!, key: \.originalSize)
                }
            }
            .edgeSwipe {
                onBacked_()
            }
            .navigationDestination(for: ImageCropView.self) { $0 }
            .navigationDestination(for: SelectWebImageScreen.self) { $0 }
            .confirmationDialog("画像を編集する", isPresented: $isImageEditDialogPresented, titleVisibility: .visible) {
                cropImageButton
                if !imageUrlOptions.isEmpty {
                    changeImageButton
                }
            }
            .task {
                do {
                    if let sourceUrl = item.sourceUrl {
                        let detail = try await generateEcItemDetail(url: sourceUrl)
                        imageUrlOptions = try detail.imageUrls()
                    }
                } catch {
                    logger.critical("\(error)")
                }
            }
            .task {
                do {
                    if item.sourceUrl != nil {
                        item = try await item.copyWithPropertiesFromSourceUrl()
                    }
                } catch {
                    logger.critical("\(error)")
                }
            }
        }
    }
}

#Preview {
    struct PreviewView: View {
        @State var item = sampleItems.first { $0.name == "from gu purchased history" }!

        var body: some View {
            DependencyInjector {
                WebItemDetail(item: item)
            }
        }
    }

    return PreviewView()
}
