//
//  UserInfoScreen.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/08/12.
//

import SwiftUI

private let logger = getLogger(#file)

struct UserInfoScreen: View {
    @EnvironmentObject var itemStore: ItemStore
    @EnvironmentObject var navigation: NavigationManager
    @State var activeSheet: ActiveSheet? = nil
    enum ActiveSheet: Int, Identifiable {
        case export,
             import_

        var id: Int {
            rawValue
        }
    }

    func row(_ key: String, _ value: String? = nil, action: (() -> Void)? = nil) -> some View {
        HStack {
            Text(key)
            Spacer()

            if let value {
                Text(value)
                    .foregroundColor(.gray)
            }

            if let action {
                Button {
                    action()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
    }

    func simpleTextSheet(_ text: String) -> some View {
        Text(text)
            .interactiveDismissDisabled()
    }

    var body: some View {
        Form {
            Section("開発者向け") {
                row("データソース", Config.DATA_SOURCE.rawValue)
                row("Build Config", Config.BUILD_CONFIG)
                row("エクスポート") {
                    activeSheet = .export

                    Task {
                        var items = itemStore.items
                        // TODO: すべてのアイテムにする
                        items = Array(items.prefix(3))
                        try await LocalJsonItemDataSource.shared.create(items)
                        activeSheet = nil
                    }
                }

                row("インポート") {
                    activeSheet = .import_

                    Task {
                        do {
                            var items = try await LocalJsonItemDataSource.shared.fetch()

                            items = items.filter { item in
                                guard !itemStore.items.contains(where: { item_ in
                                    item.id == item_.id
                                }) else {
                                    logger.warning("item \(item.id) has already exist")
                                    return false
                                }
                                return true
                            }

                            guard !items.isEmpty else {
                                throw "no items to import"
                            }

                            try await itemStore.create(items)
                        } catch {
                            logger.error("\(error)")
                        }
                        activeSheet = nil
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            Group {
                switch sheet {
                case .export:
                    Text("「ファイル」Appにエクスポート中")
                case .import_:
                    Text("「ファイル」Appからインポート中")
                }
            }
            .interactiveDismissDisabled()
        }
    }
}

#Preview {
    DependencyInjector {
        UserInfoScreen()
    }
}
