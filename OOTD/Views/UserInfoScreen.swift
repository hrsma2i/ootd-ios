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
                async let exportItemsTask: () = itemStore.export(LocalJsonItemRepository.shared)
                async let exportOutfitsTask: () = outfitStore.export(LocalJsonOutfitRepository.shared)

                do { try await exportItemsTask } catch { logger.warning("\(error)") }

                do { try await exportOutfitsTask } catch { logger.warning("\(error)") }

                activeSheet = nil
            }
        }
    }

    var importRow: some View {
        row("インポート") {
            activeSheet = .import_

            Task {
                async let importItemsTask: () = itemStore.import_(LocalJsonItemRepository.shared)
                async let importOutfitsTask: () = outfitStore.import_(LocalJsonOutfitRepository.shared)

                do { try await importItemsTask } catch { logger.warning("\(error)") }

                do { try await importOutfitsTask } catch { logger.warning("\(error)") }

                outfitStore.joinItems(itemStore.items)

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
