//
//  WebItemDetail.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/09/28.
//

import SwiftUI

private let logger = getLogger(#file)

struct WebItemDetail: HashableView {
    @State var item: Item
    var onCreated: (Item) -> Void = { _ in }
    var onBacked: (Item) -> Void = { _ in }

    @State private var isImageEditDialogPresented: Bool = false
    @State private var imageUrlOptions: [String] = []
    @EnvironmentObject var navigation: NavigationManager
    @EnvironmentObject var itemStore: ItemStore

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
                let originalImage = try await item.getUiImage()

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
                Task {
                    try await itemStore.create([item])
                }
                navigation.path.removeLast()
                onCreated(item)
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                imageRow

                VStack(spacing: 20) {
                    ItemDetail.NameRow(text: item.name)

                    section {
                        propertyRow("カテゴリー", item.originalCategoryPath?.joined(separator: " > ") ?? "-")
                        Divider()
                        propertyRow("カラー", item.originalColor ?? "-")
                        Divider()
                        propertyRow("ブランド", item.originalBrand ?? "-")
                        Divider()
                        propertyRow("サイズ", item.originalSize ?? "-")
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
                logger.error("\(error)")
            }
        }
        .task {
            do {
                if item.sourceUrl != nil {
                    item = try await item.copyWithPropertiesFromSourceUrl()
                }
            } catch {
                logger.error("\(error)")
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
