//
//  SampleOutfitDataSource.swift
//  Closet
//
//  Created by Hiroshi Matsui on 2024/07/14.
//

import Foundation

class SampleOutfitDataSource: OutfitDataSource {
    func fetch() async throws -> [Outfit] {
        sampleOutfits
    }

    func create(_: [Outfit]) {}

    func update(_: [Outfit]) async throws {}

    func delete(_: [Outfit]) async throws {}
}

let sampleOutfits = [
    Outfit(
        items: [
            "thurmont_glasses",
            "gu_suede_touch_jacket_cb_camel",
            "hardrock_T_shirts",
            "black_cocoon_denim",
            "Dr_Martens_3hole",

        ].compactMap { name in
            sampleItems.filter {
                guard case let .url(url) = $0.imageSource else { return false }
                return url.contains(name)
            }.first
        }
    ),
    Outfit(
        items: [
            "wellington_glasses",
            "purple_cap",
            "stripe_cream_shirts",
            "black_cocoon_denim",
            "adadias_samba_naby",
        ].compactMap { name in
            sampleItems.filter {
                guard case let .url(url) = $0.imageSource else { return false }
                return url.contains(name)
            }.first
        }
    ),
    Outfit(
        items: [
            "black_cocoon_denim",
            "adadias_samba_naby",
        ].compactMap { name in
            sampleItems.filter {
                guard case let .url(url) = $0.imageSource else { return false }
                return url.contains(name)
            }.first
        }
    ),
    Outfit(
        items: [
            "white_ma1",
            "3d_knit",
            "black_leather_pants",
            "clarks_black_wallabee_boots",
        ].compactMap { name in
            sampleItems.filter {
                guard case let .url(url) = $0.imageSource else { return false }
                return url.contains(name)
            }.first
        },
        imageSource: .url("https://images.wear2.jp/coordinate/rliwyvYY/0r5BWoTz/1679204559_500.jpg")
    ),
    Outfit(
        items: [],
        imageSource: .url("https://images.wear2.jp/coordinate/rliwyvYY/G9xK97Yi/1682324037_500.jpg")
    ),
]
