//
//  UserInfoScreen.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/08/12.
//

import SwiftUI

struct UserInfoScreen: View {
    @EnvironmentObject var itemStore: ItemStore
    @EnvironmentObject var outfitStore: OutfitStore
    @EnvironmentObject var navigation: NavigationManager
    @EnvironmentObject var snackbarStore: SnackbarStore

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

    var exportRow: some View {
        row("エクスポート") {
            activeSheet = .export

            Task {
                async let exportItemsTask: () = itemStore.export(to: (repository: LocalJsonItemRepository.shared, storage: LocalStorage.documentsBuckup))
                async let exportOutfitsTask: () = outfitStore.export(
                    to: (repository: LocalJsonOutfitRepository.shared, storage: LocalStorage.documentsBuckup),
                    itemsToJoin: itemStore.items
                )

                do { try await exportItemsTask } catch { logger.critical("\(error)") }

                do { try await exportOutfitsTask } catch { logger.critical("\(error)") }

                activeSheet = nil
            }
        }
    }

    var importRow: some View {
        row("インポート") {
            activeSheet = .import_

            Task {
                await snackbarStore.notify(logger) {
                    let fromItemRepository = LocalJsonItemRepository.shared
                    try await itemStore.import_(from: (repository: fromItemRepository, storage: LocalStorage.documentsBuckup))

                    let items = try await GetItems(repository: fromItemRepository)()
                    try await outfitStore.import_(
                        from: (repository: LocalJsonOutfitRepository.shared, storage: LocalStorage.documentsBuckup),
                        itemsToJoin: items
                    )
                }

                activeSheet = nil
            }
        }
    }

    var body: some View {
        Form {
            Section("開発者向け") {
                row("データソース", Config.DATA_SOURCE.rawValue)
                row("Build Config", Config.BUILD_CONFIG)
                exportRow
                importRow
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
