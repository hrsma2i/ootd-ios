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
        originalItems = items
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
                    let originalImage = try await item.imageSource.getUiImage()

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
    
    static func section(@ViewBuilder content: @escaping () -> some View) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(Color(gray: 0.96))
            
            VStack {
                content()
            }
            .padding()
        }
    }
    
    func section(@ViewBuilder content: @escaping () -> some View) -> some View {
        Self.section(content: content)
    }

    static func propertyRow(_ key: String, _ value: String, action: (() -> Void)? = nil) -> some View {
        HStack {
            Text(key)
                .foregroundColor(.init(gray: 0.5))
            Spacer()
            if let action {
                Button(action: action) {
                    Text(value)
                        .bold()
                }
            } else {
                Text(value)
                    .bold()
            }
        }
    }
    
    func propertyRow(_ key: String, _ value: String, action: (() -> Void)? = nil) -> some View {
        Self.propertyRow(key, value, action: action)
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
                    .multilineTextAlignment(.leading)
                    .bold()
                Spacer()
            }
        }
    }
    
    struct NameRow: View {
        @State var text: String
        @State var isEditing: Bool
        var onSubmit: (String) -> Void
        
        init(text: String, onSubmit: @escaping (String) -> Void = { _ in }) {
            self.text = text
            isEditing = text == ""
            self.onSubmit = onSubmit
        }
        
        var body: some View {
            Group {
                if isEditing {
                    TextField("アイテム名を入力...", text: $text) {
                        onSubmit(text)
                        if text != "" {
                            isEditing = false
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                } else {
                    HStack {
                        Text(text)
                            .foregroundColor(.black)
                            .bold()

                        Button {
                            isEditing = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                        
                        Spacer()
                    }
                }
            }
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
    
    static func priceRow(_ item: Item, action: (() -> Void)? = nil) -> some View {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 0

        let value: String
        if let price = item.purchasedPrice,
           let formattedPrice = formatter.string(from: NSNumber(value: price))
        {
            value = formattedPrice
        } else {
            value = "¥ -"
        }

        return propertyRow("購入金額", value, action: action)
    }
    
    func priceRow(_ item: Item) -> some View {
        Self.priceRow(item) {}
    }

    static func descriptionRow(_ description: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("説明")
                    .foregroundColor(.init(gray: 0.5))

                Text(description)
            }
            Spacer()
        }
    }
    
    func descriptionRow(_ description: String) -> some View {
        Self.descriptionRow(description)
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
                            priceRow(item)
                        }
                        
                        section {
                            propertyRow("購入日", item.purchasedOn?.toString(hasTime: false) ?? "----/--/--") {}
                            Divider()
                            propertyRow("作成日時", item.createdAt?.toString() ?? "----/--/-- --:--:--")
                            Divider()
                            propertyRow("更新日時", item.updatedAt?.toString() ?? "----/--/-- --:--:--")
                        }
                    
                        if let urlString = item.sourceUrl {
                            section {
                                urlRow(urlString)
                            }
                        }

                        section {
                            propertyRow("カテゴリー", item.originalCategoryPath?.joined(separator: " > ") ?? "-")
                            Divider()
                            propertyRow("カラー", item.originalColor ?? "-")
                            Divider()
                            propertyRow("ブランド", item.originalBrand ?? "-")
                            Divider()
                            propertyRow("サイズ", item.originalSize ?? "-")
                            Divider()
                            descriptionRow(item.originalDescription ?? "")
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
    enum Pattern {
        case singleNil
        case singleFilled
        case multiple
    }
    
    struct SwitchableView: View {
        @State private var pattern: Pattern = .singleFilled

        var body: some View {
            DependencyInjector {
                VStack {
                    switch pattern {
                    case .singleFilled:
                        ItemDetail(
                            items: [sampleItems.first { $0.name != "" }!],
                            mode: .update
                        )
                    case .singleNil:
                        ItemDetail(
                            items: [sampleItems.filter { $0.name == "" }.randomElement()!],
                            mode: .update
                        )
                    case .multiple:
                        ItemDetail(
                            items: Array(sampleItems[0 ... 4]),
                            mode: .update
                        )
                    }
                    
                    Spacer()
                    Divider()
                    HStack {
                        Button(action: { pattern = .singleFilled }) {
                            Text("単体")
                        }
                        
                        Spacer()
                        
                        Button(action: { pattern = .singleNil }) {
                            Text("単体（nil）")
                        }
                        
                        Spacer()

                        Button(action: { pattern = .multiple }) {
                            Text("複数")
                        }
                    }
                    .padding()
                }
            }
        }
    }

    return SwitchableView()
}
