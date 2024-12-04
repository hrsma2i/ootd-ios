//
//  EditOutfits.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/27.
//

import Foundation

private let logger = getLogger(#file)

struct EditOutfits {
    let repository: OutfitRepository

    // この関数内で .updatedAt などを更新するので、更新後の [Outfit] を返す必要がある
    func callAsFunction(_ editedOutfits: [Outfit], originalOutfits: [Outfit]) async throws -> [Outfit] {
        let outfitsToUpdate: [Outfit]

        if originalOutfits.isEmpty {
            outfitsToUpdate = editedOutfits
        } else if editedOutfits.count == originalOutfits.count {
            outfitsToUpdate = zip(originalOutfits, editedOutfits).compactMap { original, edited -> Outfit? in

                if original == edited {
                    return nil
                }

                logger.debug("""
                original outfit:
                    id: \(original.id)
                    items:
                    - \(original.items.map(\.id).joined(separator: "\n    - "))

                edited outfit:
                    id: \(edited.id)
                    items:
                    - \(edited.items.map(\.id).joined(separator: "\n    - "))
                """)

                return edited
            }
        } else {
            throw "originalOutfits is empty and originalOutfits.count != editedOutfits.count"
        }

        let now = Date()
        let updatedOutfits = outfitsToUpdate.map {
            $0
                .copyWith(\.updatedAt, value: now)
        }

        try await repository.update(editedOutfits)

        return updatedOutfits
    }
}
