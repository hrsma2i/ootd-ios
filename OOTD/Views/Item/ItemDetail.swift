//
//  ItemDetail.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/06/26.
//

import SwiftUI

private let logger = getLogger(#file)

struct ItemDetail: HashableView {
    @State var items: [Item]
    @EnvironmentObject var itemStore: ItemStore
    @EnvironmentObject var navigation: NavigationManager
    
    // MARK: - private
    
    private let originalItems: [Item]
    @State private var isAlertPresented: Bool = false
    
    private enum ActiveSheet: Int, Identifiable {
        case categorySelect
        
        var id: Int {
            rawValue
        }
    }
    
    @State private var activeSheet: ActiveSheet?
    
    init(items: [Item]) {
        self.items = items
        self.originalItems = items
    }
    
    var hasNewItems: Bool {
        items.contains { $0.id == nil }
    }
    
    var hasChanges: Bool {
        if hasNewItems {
            return true
        } else {
            return zip(items, originalItems).contains { item, originalItem in
                item != originalItem
            }
        }
    }
    
    var categoryDisplayed: String {
        if let category = items.first?.category, items.allSatisfy({ $0.category == category }) {
            return category.rawValue
        }
        return "バラバラ"
    }
    
    var saveButton: some View {
        VStack {
            Spacer()
            RoundRectangleButton(
                text: "保存",
                systemName: "checkmark",
                fontSize: 20
            ) {
                var newItems: [Item] = []
                var existingItems: [Item] = []
                var existingOriginalItems: [Item] = []
                
                for (i, item) in items.enumerated() {
                    if item.id == nil {
                        newItems.append(item)
                    } else {
                        existingItems.append(item)
                        existingOriginalItems.append(originalItems[i])
                    }
                }
                
                Task {
                    try await itemStore.create(newItems)
                }
                Task {
                    try await itemStore.update(existingItems, originalItems: existingOriginalItems)
                }
                
                navigation.path.removeLast()
            }
        }
    }
    
    func itemCard(_ item: Item, index: Int = 0, aspectRatio: CGFloat?) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ItemCard(
                item: item,
                padding: 0,
                aspectRatio: aspectRatio
            )
            
            Button {
                Task {
                    let onCropped: (UIImage) -> Void = { uiImage in
                        // 新規アイテムの id=nil なので、 Item.id ではなく index で特定する
                        items[index] = item
                            .copyWith(\.imageURL, value: nil)
                            .copyWith(\.image, value: uiImage)
                        
                        navigation.path.removeLast()
                    }
                    
                    let view: ImageCropView
                    if let url = item.imageURL {
                        let data = try await downloadImage(url)
                        view = try ImageCropView(data: data, onCropped: onCropped)
                    } else if let uiImage = item.image {
                        view = ImageCropView(uiImage: uiImage, onCropped: onCropped)
                    } else if let imagePath = item.imagePath {
                        let uiImage = try LocalStorage.loadImage(from: imagePath)
                        view = ImageCropView(uiImage: uiImage, onCropped: onCropped)
                    } else {
                        logger.error("no item image")
                        return
                    }
                    
                    navigation.path.append(view)
                }
            } label: {
                var height: CGFloat = 40
                var fontSize: CGFloat = 23
                var padding: CGFloat = 10
                if items.count >= 2 {
                    height *= 0.75
                    fontSize *= 0.75
                    padding *= 0.75
                }
                return Circle()
                    .foregroundColor(.black)
                    .opacity(0.5)
                    .frame(height: height)
                    .overlay {
                        Image(systemName: "crop")
                            .foregroundColor(.white)
                            .font(.system(size: fontSize))
                    }
                    .padding(padding)
            }
        }
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
                if hasChanges {
                    isAlertPresented = true
                } else {
                    navigation.path.removeLast()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(20)
        }
    }
    
    @ViewBuilder
    var imageArea: some View {
        ZStack(alignment: .topLeading) {
            if items.count == 1, let item = items.first {
                itemCard(item, aspectRatio: nil)
                    .listRowInsets(.init())
            } else {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(0 ..< items.count, id: \.self) { i in
                            itemCard(items[i], index: i, aspectRatio: 1)
                        }
                        .frame(height: 300)
                    }
                }
            }
            
            backButton
        }
    }
    
    func section(content: @escaping () -> some View) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color(gray: 0.96))
            
            content()
                .padding()
        }
    }
    
    func propertyRow(_ key: String, _ value: String, action: @escaping () -> Void = {}) -> some View {
        HStack {
            Text(key)
            Spacer()
            Button(action: action) {
                Text(value)
            }
        }
    }
    
    var categoryRow: some View {
        propertyRow("カテゴリー", categoryDisplayed) {
            activeSheet = .categorySelect
        }
    }
    
    func urlRow(_ urlString: String) -> some View {
        Button {
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } label: {
            HStack {
                Image(systemName: "link")
                Text(urlString)
                    .lineLimit(1)
            }
        }
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                imageArea
                
                VStack(spacing: 20) {
                    section {
                        categoryRow
                    }
                    
                    if items.count == 1, let item = items.first, let urlString = item.sourceUrl {
                        section {
                            urlRow(urlString)
                        }
                    }
                }
                .padding(20)
            }
            
            if hasChanges {
                saveButton
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $activeSheet) { item in
            switch item {
            case .categorySelect:
                CategorySelectSheet { category in
                    activeSheet = nil
                    
                    if let category {
                        // items の要素のプロパティを直接書き換えても再描画されなかったので
                        items = items.map {
                            $0.copyWith(\.category, value: category)
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
        .navigationDestination(for: ImageCropView.self) { $0 }
    }
}

#Preview {
    struct SwitchableView: View {
        @State private var isSingle = false

        var body: some View {
            DependencyInjector {
                VStack {
                    if isSingle {
                        ItemDetail(
                            items: [sampleItems.randomElement()!]
                        )
                    } else {
                        ItemDetail(
                            items: Array(sampleItems[0 ... 4])
                        )
                    }
                    
                    Spacer()
                    Divider()
                    Button(action: { isSingle = !isSingle }) {
                        Text("単体・複数切り替え")
                    }
                }
            }
        }
    }

    return SwitchableView()
}
