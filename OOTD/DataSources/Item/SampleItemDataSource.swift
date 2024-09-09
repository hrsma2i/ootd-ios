//
//  SampleItemDataSource.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/07/14.
//

import Foundation

class SampleItemDataSource: ItemDataSource {
    func fetch() async throws -> [Item] {
        sampleItems
    }

    func create(_ items: [Item]) -> [Item] {
        items
    }

    func update(_: [Item]) {}

    func delete(_: [Item]) {}
}

let sampleItems = [
    Item(
        id: "thurmont_glasses",
        imageURL: "https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/thurmont_glasses.png?alt=media&token=bb7eab8b-0bd1-49a4-839c-b387a5dc9ea8",
        category: .others
    ),
    Item(
        id: "gu_suede_touch_jacket_cb_camel",
        imageURL: "https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/gu_suede_touch_jacket_cb_camel.png?alt=media&token=2106309a-0ac2-4e7f-8f3e-0665a6fe9190"
    ),
    Item(
        id: "hardrock_T_shirts",
        imageURL: "https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/hardrock_T_shirts.jpeg?alt=media&token=cb15d0ce-a16a-4edd-a638-a32e40d095b9"
    ),
    Item(
        id: "black_cocoon_denim",
        imageURL: "https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/black_cocoon_denim.jpeg?alt=media&token=e5cbade5-b60a-4c36-b69e-128600e34498"
    ),
    Item(
        id: "Dr_Martens_3hole",
        imageURL: "https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/Dr_Martens_3hole.jpg?alt=media&token=044e31d3-0cfd-436f-95df-e7b7ad0956a9"
    ),
    Item(
        id: "wellington_glasses",
        imageURL: "https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/wellington_glasses.png?alt=media&token=2623f778-c888-4f5e-90b2-0f30c4a44015",
        category: .others
    ),
    Item(
        id: "purple_cap",
        imageURL: "https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/purple_cap.jpeg?alt=media&token=ba2eab47-fed3-4db6-bc3d-790e288813ee"
    ),
    Item(
        id: "stripe_cream_shirts",
        imageURL: "https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/stripe_cream_shirts.jpeg?alt=media&token=aec61690-4dc3-4c07-8c1b-f9d26e792818"
    ),
    Item(
        id: "adadias_samba_naby",
        imageURL: "https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/adadias_samba_naby.jpeg?alt=media&token=762d73ca-7f2d-45ca-98e6-bd695a2673e3"
    ),
    Item(
        id: "white_ma1",
        imageURL: "https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/white_ma1.jpeg?alt=media&token=fc704029-f9fd-4720-a4e3-76577c7c0918"
    ),
    Item(
        id: "3d_knit",
        imageURL: "https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/3d_knit.jpeg?alt=media&token=6caeeb94-7b4b-4714-a891-e7e89d7c7f11"
    ),
    Item(
        id: "black_leather_pants",
        imageURL: "https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/black_leather_pants.jpeg?alt=media&token=0d0a7496-51f8-4ebf-a02f-734a3dbafd3b"
    ),
    Item(
        id: "clarks_black_wallabee_boots",
        imageURL: "https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/clarks_black_wallabee_boots.jpeg?alt=media&token=13f736b1-1053-4430-ac93-e96ce2872c5e",
        sourceUrl: "https://www.clarks.co.jp/commodity/SCKS0472G/CL915BM14109/"
    ),
]
