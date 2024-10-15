//
//  LocalJsonOutfitDataSource.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/15.
//

import Foundation

private let logger = getLogger(#file)

extension Outfit: Codable {
    enum CodingKeys: String, CodingKey {
        case id,
             itemIds = "item_ids"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(itemIDs, forKey: .itemIds)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        itemIDs = try container.decode([String].self, forKey: .itemIds)
        items = []
    }
}

struct LocalJsonOutfitDataSource: OutfitDataSource {
    static let shared: LocalJsonOutfitDataSource = .init()

    private init() {}

    let className = String(describing: Self.self)

    func header(funcName: String = #function) -> String {
        "[\(className).\(#function)]"
    }

    func backup(_ path: String) -> String {
        "backup/\(path)"
    }

    func fetch() async throws -> [Outfit] {
        let decoder = JSONDecoder()
        let data = try LocalStorage.documents.load(from: backup("outfits.json"))
        var outfits = try decoder.decode([Outfit].self, from: data)
        outfits = outfits.map { outfit in
            let imagePath = backup(outfit.imagePath)
            if LocalStorage.documents.exists(at: imagePath) {
                return outfit.copyWith(\.imageSource, value: .documents(backup(outfit.imagePath)))
            } else {
                // 画像がない場合は imageSource = nil のままにする。 ImageCard で読み込みエラーが出たりするから。
                return outfit
            }
        }
        return outfits
    }

    func create(_ outfits: [Outfit]) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // オプション: JSONを読みやすくフォーマット
        let jsonData = try encoder.encode(outfits)

        for outfit in outfits {
            // Item と違い、画像がない場合が多々ある
            do {
                guard let image = try await outfit.imageSource?.getUiImage() else {
                    // 画像がない場合は特に何もしない
                    continue
                }
                try LocalStorage.documents.save(image: image, to: backup(outfit.imagePath))
            } catch {
                logger.warning("\(error)")
            }
        }

        try LocalStorage.documents.save(data: jsonData, to: backup("outfits.json"))
    }

    func update(_ outfits: [Outfit]) async throws {
        throw "\(header()) not implemented"
    }

    func delete(_ outfits: [Outfit]) async throws {
        throw "\(header()) not implemented"
    }
}
