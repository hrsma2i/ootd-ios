//
//  LocalJsonOutfitRepository.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/10/15.
//

import Foundation

private let logger = getLogger(#file)

extension Outfit: Codable {
    enum CodingKeys: String, CodingKey {
        case id,
             itemIds = "item_ids",
             tags
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
        tags = try container.decode([String].self, forKey: .tags)
    }
}

struct LocalJsonOutfitRepository: OutfitRepository {
    static let shared: LocalJsonOutfitRepository = .init()

    private init() {}

    let className = String(describing: Self.self)

    func header(funcName: String = #function) -> String {
        "[\(className).\(#function)]"
    }

    func backup(_ path: String) -> String {
        "backup/\(path)"
    }

    func findAll() async throws -> [Outfit] {
        let decoder = JSONDecoder()
        let data = try await LocalStorage.documents.load(from: backup("outfits.json"))
        var outfits = try decoder.decode([Outfit].self, from: data)
        outfits = await outfits.asyncMap(isParallel: false) { outfit in
            let imagePath = backup(outfit.imagePath)
            let imageExists = (try? await LocalStorage.documents.exists(at: imagePath)) ?? false
            if imageExists {
                return outfit.copyWith(\.imageSource, value: .documents(backup(outfit.imagePath)))
            } else {
                // 画像がない場合は imageSource = nil のままにする。 ImageCard で読み込みエラーが出たりするから。
                return outfit
            }
        }
        return outfits
    }

    func save(_ outfits: [Outfit]) async throws {
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
                try await LocalStorage.documents.saveImage(image: image, to: backup(outfit.imagePath))
            } catch {
                logger.warning("\(error)")
            }
        }

        try await LocalStorage.documents.save(data: jsonData, to: backup("outfits.json"))
    }

    func delete(_ outfits: [Outfit]) async throws {
        throw "\(header()) not implemented"
    }
}
