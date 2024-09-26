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
    let mode: DetailMode
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
    
    init(items: [Item], mode: DetailMode) {
        self.items = items
        self.originalItems = items
        self.mode = mode
    }
    
    var hasChanges: Bool {
        if mode == .create {
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
                Task {
                    switch mode {
                    case .create:
                        try await itemStore.create(items)
                    case .update:
                        try await itemStore.update(items, originalItems: originalItems)
                    }
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
                    let originalImage = try await item.getUiImage()

                    navigation.path.append(
                        ImageCropView(uiImage: originalImage) { editedImage in
                            items[index] = item
                                .copyWith(\.imageSource, value: .uiImage(editedImage))
                                .copyWith(\.thumbnailSource, value: .uiImage(editedImage))

                            navigation.path.removeLast()
                        }
                    )
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
    
    func backWithAlertIfChanged() {
        if hasChanges {
            isAlertPresented = true
        } else {
            navigation.path.removeLast()
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
    
    func section(@ViewBuilder content: @escaping () -> some View) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color(gray: 0.96))
            
            VStack {
                content()
            }
            .padding()
        }
    }
    
    func propertyRow(_ key: String, _ value: String, action: (() -> Void)? = nil) -> some View {
        HStack {
            Text(key)
            Spacer()
            if let action {
                Button(action: action) {
                    Text(value)
                }
            } else {
                Text(value)
                    .foregroundColor(.init(gray: 0.75))
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
    
    struct NameRow: View {
        @State var text: String
        var onSubmit: (String) -> Void = { _ in }
        
        var body: some View {
            TextField("アイテム名を入力...", text: $text) {
                onSubmit(text)
            }
            .bold()
            .font(.title2)
        }
    }
    
    @ViewBuilder
    var nameRow: some View {
        if items.count == 1, let item = items.first {
            NameRow(text: item.name) { newName in
                update(\.name, newName, only: item)
            }
        }
    }
    
    func update<T>(_ key: WritableKeyPath<Item, T>, _ value: T, only item: Item? = nil) {
        // items から取り出したものを直接更新しても再描画されないので items まるごと更新する
        items = items.map { item_ in
            if let item, item_.id != item.id {
                return item_
            }
            return item_.copyWith(key, value: value)
        }
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                imageArea
                
                VStack(spacing: 20) {
                    nameRow
                    
                    section {
                        categoryRow
                    }
                    
                    if items.count == 1, let item = items.first {
                        section {
                            propertyRow("作成日時", item.createdAt?.toString() ?? "----/--/-- --:--:--")
                            Divider()
                            propertyRow("更新日時", item.updatedAt?.toString() ?? "----/--/-- --:--:--")
                        }
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
        .edgeSwipe { backWithAlertIfChanged() }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .categorySelect:
                CategorySelectSheet { category in
                    activeSheet = nil
                    
                    if let category {
                        update(\.category, category)
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
        @State private var isSingle = true

        var body: some View {
            DependencyInjector {
                VStack {
                    if isSingle {
                        ItemDetail(
                            items: [sampleItems.randomElement()!],
                            mode: .update
                        )
                    } else {
                        ItemDetail(
                            items: Array(sampleItems[0 ... 4]),
                            mode: .update
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
