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

// AppStore スクリーンショット撮影用
let sampleOutfits = [
    Outfit(
        items: [
            "marlbolo cap",
            "gray sweat",
            "baggy denim",
            "salomon",
        ].compactMap { name in
            sampleItems.filter {
                $0.name == name
            }.first
        }
    ),
    Outfit(
        items: [
            "famima t shirts",
            "real tree camo pants",
            "adidas samba",
        ].compactMap { name in
            sampleItems.filter {
                $0.name == name
            }.first
        }
    ),
    Outfit(
        items: [
            "adidas pique",
            "baggy denim",
            "nike v2k",
        ].compactMap { name in
            sampleItems.filter {
                $0.name == name
            }.first
        }
    ),
    Outfit(
        items: [
            "oma beanie",
            "arcteryx mountain parka",
            "sweat pants",
            "salomon",
        ].compactMap { name in
            sampleItems.filter {
                $0.name == name
            }.first
        }
    ),
    Outfit(
        items: [],
        imageSource: .url("https://lh3.googleusercontent.com/pw/AP1GczNuoxEmqzAoHi4S_unmGikNGjEZnxXzHBhbh3IANKs30YOWqz6Ud3h99cXzcWXsJfVHbaKyFi8jPLzPcWSmx43AzyhDd4S4k8RPqDh7VBaEEtvkUEE=w2400")
    ),
]

// 開発用
// let sampleOutfits = [
//    Outfit(
//        items: [
//            "thurmont_glasses",
//            "gu_suede_touch_jacket_cb_camel",
//            "hardrock_T_shirts",
//            "black_cocoon_denim",
//            "Dr_Martens_3hole",
//
//        ].compactMap { name in
//            sampleItems.filter {
//                guard case let .url(url) = $0.imageSource else { return false }
//                return url.contains(name)
//            }.first
//        },
//        tags: [
//            "アメカジ",
//            "バギーパンツ",
//            "古着",
//        ]
//    ),
//    Outfit(
//        items: [
//            "wellington_glasses",
//            "purple_cap",
//            "stripe_cream_shirts",
//            "black_cocoon_denim",
//            "adadias_samba_naby",
//        ].compactMap { name in
//            sampleItems.filter {
//                guard case let .url(url) = $0.imageSource else { return false }
//                return url.contains(name)
//            }.first
//        }
//    ),
//    Outfit(
//        items: [
//            "black_cocoon_denim",
//            "adadias_samba_naby",
//        ].compactMap { name in
//            sampleItems.filter {
//                guard case let .url(url) = $0.imageSource else { return false }
//                return url.contains(name)
//            }.first
//        }
//    ),
//    Outfit(
//        items: [
//            "white_ma1",
//            "3d_knit",
//            "black_leather_pants",
//            "clarks_black_wallabee_boots",
//        ].compactMap { name in
//            sampleItems.filter {
//                guard case let .url(url) = $0.imageSource else { return false }
//                return url.contains(name)
//            }.first
//        },
//        imageSource: .url("https://images.wear2.jp/coordinate/rliwyvYY/0r5BWoTz/1679204559_500.jpg"),
//        tags: [
//            "3Dニット",
//            "古着ストリート",
//            "ワラビーブーツ",
//            "Clarks",
//        ]
//    ),
//    Outfit(
//        items: [],
//        imageSource: .url("https://images.wear2.jp/coordinate/rliwyvYY/G9xK97Yi/1682324037_500.jpg")
//    ),
// ]
