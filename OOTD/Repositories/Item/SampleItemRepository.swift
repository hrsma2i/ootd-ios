//
//  SampleItemRepository.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/07/14.
//

import Foundation

class SampleItemRepository: ItemRepository {
    func findAll() async throws -> [Item] {
        sampleItems
    }

    func create(_: [Item]) {}

    func update(_: [Item]) {}

    func delete(_: [Item]) {}
}

// AppStore スクリーンショット撮影用
let sampleItems = [
    Item(
        imageSource: .url("https://lh3.googleusercontent.com/pw/AP1GczMDPp_yDUkLrNpSYr92ofDpuc4WVHCJdbgN04UFE8wpjw69BimpBO9G9sAyjAfsuMlkB66pRj-JNfU2n9ZMJFTUq2gJKkekxgBX_2v7vXlN0sPSWZE=w2400"),
        option: .init(
            name: "marlbolo cap",
            category: .others
        )
    ),
    Item(
        imageSource: .url("https://lh3.googleusercontent.com/pw/AP1GczN37a2OxZWuuFhgc0V5mgEUM76wf8xwGgkOiwJkRvfisUHr-a6XbVDbNgZVEyNK2fKR0tXB_JL7xZMIgxNS7mwPYT2vSKdzavCUmmpeQpvpuD0SG-0=w2400"),
        option: .init(
            name: "famima t shirts",
            category: .halfInnerTops
        )
    ),
    Item(
        imageSource: .url("https://lh3.googleusercontent.com/pw/AP1GczOCGS6_8gRn_I1h9P1wgLr7vZEHIPVmPN6xqWt6l4DK1Y1ZzpEBwjbDlD8gxdaGDZkr6h4H8zdUPcb2BQY5lbhNdGaB4ItB_mGWYDDpEimTWkf41jU=w2400"),
        option: .init(
            name: "adidas pique",
            category: .longInnerTops
        )
    ),
    Item(
        imageSource: .url("https://lh3.googleusercontent.com/pw/AP1GczOh7IGSu5w49BXKxtw3VJCb5VbLzDi3cQed_iUlTAiH9Q5JBiYk_yEKyEB-7jxURHHcXPt_lGVAzTXRJ84aQSzG39zDzwydR86Ok8g5SbgTBpmm2iM=w2400"),
        option: .init(
            name: "oma beanie",
            category: .others
        )
    ),
    Item(
        imageSource: .url("https://lh3.googleusercontent.com/pw/AP1GczMwvbueFzUShwH7ah6V1LBYZGqSTfebf9Wrrz3LVv54bFcUAi1MBNYq_KI7mjM_vuOiPXl0Yrgak-7eT9i6zr_Wry3J6ITK4yfAOpbVns82ywKriPs=w2400"),
        option: .init(
            name: "arcteryx mountain parka",
            category: .outerwear
        )
    ),
    Item(
        imageSource: .url("https://lh3.googleusercontent.com/pw/AP1GczMQK5zmGGyMk7mzqOpJPl38C60PW7-UTxSL3Uebs_LLhRqCWlsBqgC7RTspGjgTkWnXkVyQn9RVwVrq5u2OTA_-d4g4ZOkAcbE9eB3vO0FKFKhYOYE=w2400"),
        option: .init(
            name: "denim jacket",
            category: .outerwear
        )
    ),
    Item(
        imageSource: .url("https://lh3.googleusercontent.com/pw/AP1GczOyPjj-GxIwcGgcn55WysOZqqHb4vozZWNJoFZ1njH5slnML8GlDCRwhZDzfF1vfV3_bdVbsi6OVTR3UO2lUthRuVzhkQCLMEz8MPlK6HdZcMpu5a0=w2400"),
        option: .init(
            name: "baggy denim",
            category: .bottoms
        )
    ),
    Item(
        imageSource: .url("https://lh3.googleusercontent.com/pw/AP1GczOkd7Y4YTqeP4tn8ThDLS2RQKTWZwCzcBKsH-knc-3rYHkeRFESJix2qlfJpaxSB-Cju-uBGxr9_QtPaCtTB8Na16No0mz_kyKJsEny2Im_pe1rnpM=w2400"),
        option: .init(
            name: "sweat pants",
            category: .bottoms
        )
    ),
    Item(
        imageSource: .url("https://lh3.googleusercontent.com/pw/AP1GczOIMlFQxM0XWXZM8M9AvfS2S0oJXkoPahRzByLYuhonmOx-UZQj8aoHx_u8fxH-w903lO2h61T8d7hFHcD8-zTBdAds1DaFi9yzKZX2-JZ7ahViK6A=w2400"),
        option: .init(
            name: "gray sweat",
            category: .middleTops
        )
    ),
    Item(
        imageSource: .url("https://lh3.googleusercontent.com/pw/AP1GczMwsRDFHUYA9o6jKNHyWb-8i-wBYxIUKUSABEmxD5S8qfw2HuMhH5p-BEFKpaxDIzh44zb-0ch3z4hzKOtncS2R_a3AneUIhU8InZEMBFbpNHBDlcA=w2400"),
        option: .init(
            name: "real tree camo pants",
            category: .bottoms
        )
    ),
    Item(
        imageSource: .url("https://lh3.googleusercontent.com/pw/AP1GczMxr2Qj2ZnbKh1tRTgHg-qAV__RXLF75W_9E8NYIsobaEEFAKmkmFf7qmoM9sf9ze_nJB3-Sn3N2uEjILGNbrOlAoGjVJTaOfHNfKDgbSyoHfBE7Ik=w2400"),
        option: .init(
            name: "salomon",
            category: .shoes
        )
    ),
    Item(
        imageSource: .url("https://lh3.googleusercontent.com/pw/AP1GczMrxt5EByftjKTRcCqAG0AXaOgnEBc0XlPgAyGc3mEfxBCHegcdQ4Rc9aPz5jUeV9yFGYMpaqljWf6FIeIIx3LLs_MYANFEkPDI5df5QujjwGC608s=w2400"),
        option: .init(
            name: "nike v2k",
            category: .shoes
        )
    ),
    Item(
        imageSource: .url("https://lh3.googleusercontent.com/pw/AP1GczORzmssI27w-XaY6rYsR_qJP6tnFo9FTG-rxg6ju1XcSRyz0kFSAi2OFXGUQ8WlqoCtgGtapEHh6poauacZ8EfTTVMH4p-YGLYKeYcuntkqy-CtLxw=w2400"),
        option: .init(
            name: "adidas samba",
            category: .shoes
        )
    ),
]

// 開発用
// let sampleItems = [
//    Item(
//        imageSource: .url("https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/thurmont_glasses.png?alt=media&token=bb7eab8b-0bd1-49a4-839c-b387a5dc9ea8"),
//        option: .init(
//            category: .others,
//            tags: ["共通タグ1"]
//        )
//    ),
//    Item(
//        imageSource: .url("https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/gu_suede_touch_jacket_cb_camel.png?alt=media&token=2106309a-0ac2-4e7f-8f3e-0665a6fe9190"),
//        option: .init(
//            tags: ["共通タグ1"]
//        )
//    ),
//    Item(
//        imageSource: .url("https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/hardrock_T_shirts.jpeg?alt=media&token=cb15d0ce-a16a-4edd-a638-a32e40d095b9"),
//        option: .init(
//            tags: ["共通タグ1"]
//        )
//    ),
//    Item(
//        imageSource: .url("https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/black_cocoon_denim.jpeg?alt=media&token=e5cbade5-b60a-4c36-b69e-128600e34498"),
//        option: .init(
//            tags: ["共通タグ1"]
//        )
//    ),
//    Item(
//        imageSource: .url("https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/Dr_Martens_3hole.jpg?alt=media&token=044e31d3-0cfd-436f-95df-e7b7ad0956a9"),
//        option: .init(
//            name: "Dr.Martens　1461 3ホール 10085001",
//            category: .shoes,
//            tags: ["ドレスシューズ", "Dr. Martnes", "マーチン", "きれいめ", "ブーツ", "雨の日", "共通タグ1"],
//            purchasedPrice: 25_300,
//            sourceUrl: "https://zozo.jp/shop/jackandmarie/goods/67932863/?did=113101990",
//            originalCategoryPath: ["シューズ", "その他シューズ"],
//            originalColor: "ブラック",
//            originalBrand: "Dr. Martens",
//            originalSize: "26",
//            originalDescription: """
//                Dr.Martens 1461 3ホール
//                1961年４月１日に誕生し、この日がネーミングの元になった1461の３ホールシューズ。数十年にわたってドクターマーチンのアイコン的存在で発売当時は耐久性のある労働者の靴として売られてました。
//
//
//                ※お客様のモニターの設定や閲覧環境(OSやブラウザのバージョン)によって、画面上と商品実物との色味が若干異なる場合があります。あらかじめご了承ください。
//
//                ※2023年10月1日より、価格改定させていただきます。商品タグに記載している価格が旧価格のものが混在しておりますが、現在はこちらの価格での販売となります。ご了承頂きますよう、よろしくお願い申し上げます。
//            """
//        )
//    ),
//    Item(
//        imageSource: .url("https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/wellington_glasses.png?alt=media&token=2623f778-c888-4f5e-90b2-0f30c4a44015"),
//        option: .init(
//            category: .others
//        )
//    ),
//    Item(
//        imageSource: .url("https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/purple_cap.jpeg?alt=media&token=ba2eab47-fed3-4db6-bc3d-790e288813ee")
//    ),
//    Item(
//        imageSource: .url("https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/stripe_cream_shirts.jpeg?alt=media&token=aec61690-4dc3-4c07-8c1b-f9d26e792818")
//    ),
//    Item(
//        imageSource: .url("https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/adadias_samba_naby.jpeg?alt=media&token=762d73ca-7f2d-45ca-98e6-bd695a2673e3")
//    ),
//    Item(
//        imageSource: .url("https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/white_ma1.jpeg?alt=media&token=fc704029-f9fd-4720-a4e3-76577c7c0918")
//    ),
//    Item(
//        imageSource: .url("https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/3d_knit.jpeg?alt=media&token=6caeeb94-7b4b-4714-a891-e7e89d7c7f11")
//    ),
//    Item(
//        imageSource: .url("https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/black_leather_pants.jpeg?alt=media&token=0d0a7496-51f8-4ebf-a02f-734a3dbafd3b")
//    ),
//    Item(
//        imageSource: .url("https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/clarks_black_wallabee_boots.jpeg?alt=media&token=13f736b1-1053-4430-ac93-e96ce2872c5e"),
//        option: .init(
//            sourceUrl: "https://www.clarks.co.jp/commodity/SCKS0472G/CL915BM14109/"
//        )
//    ),
//    Item(
//        imageSource: .url("https://firebasestorage.googleapis.com/v0/b/closet-app-649ec.appspot.com/o/Dr_Martens_3hole.jpg?alt=media&token=044e31d3-0cfd-436f-95df-e7b7ad0956a9"),
//        option: .init(
//            name: "from zozo purchased history",
//            purchasedPrice: 25_300,
//            purchasedOn: Date(year: 2024, month: 9, day: 28),
//            sourceUrl: "https://zozo.jp/sp/?c=gr&did=113101990",
//            originalColor: "ブラック",
//            originalBrand: "Dr. Martens",
//            originalSize: "26"
//        )
//    ),
//    Item(
//        imageSource: .url("https://image.uniqlo.com/GU/ST3/AsianCommon/imagesgoods/352152/item/goods_67_352152_3x4.jpg?width=400"),
//        option: .init(
//            name: "from gu purchased history",
//            purchasedOn: Date(year: 2024, month: 9, day: 28),
//            sourceUrl: "https://www.gu-global.com/jp/ja/products/E352152-000/00",
//            originalColor: "67 BLUE",
//            originalBrand: "GU",
//            originalSize: "WOMEN XL"
//        )
//    ),
// ]
