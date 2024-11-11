//
//  BannerView.swift
//  OOTD
//
//  Created by Hiroshi Matsui on 2024/11/11.
//

import GoogleMobileAds
import SwiftUI

struct AdBanner: UIViewRepresentable {
    let adSize: GADAdSize

    init(_ adSize: GADAdSize) {
        self.adSize = adSize
    }

    func makeUIView(context: Context) -> UIView {
        // Wrap the GADBannerView in a UIView. GADBannerView automatically reloads a new ad when its
        // frame size changes; wrapping in a UIView container insulates the GADBannerView from size
        // changes that impact the view returned from makeUIView.
        let view = UIView()
        view.addSubview(context.coordinator.bannerView)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.bannerView.adSize = adSize
    }

    func makeCoordinator() -> BannerCoordinator {
        return BannerCoordinator(self)
    }

    // [END create_banner_view]

    // [START create_banner]
    class BannerCoordinator: NSObject, GADBannerViewDelegate {
        private(set) lazy var bannerView: GADBannerView = {
            let banner = GADBannerView(adSize: parent.adSize)
            // [START load_ad]
            banner.adUnitID = Config.GOOGLE_ADMOB_AD_UNIT_ID
            banner.load(GADRequest())
            // [END load_ad]
            // [START set_delegate]
            banner.delegate = self
            // [END set_delegate]
            return banner
        }()

        let parent: AdBanner

        init(_ parent: AdBanner) {
            self.parent = parent
        }

        // [END create_banner]

        // MARK: - GADBannerViewDelegate methods

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("DID RECEIVE AD.")
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("FAILED TO RECEIVE AD: \(error.localizedDescription)")
        }
    }
}

struct AdBannerContainer<Content: View>: View {
    var content: () -> Content

    // [START add_banner_to_view]
    var body: some View {
        GeometryReader { geometry in
            let adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(geometry.size.width)

            VStack(spacing: 0) {
                AdBanner(adSize)
                    .frame(height: adSize.size.height)

                content()
            }
        }
    }
}

#Preview {
    DependencyInjector {
        AdBannerContainer {
            OutfitGrid()
        }
    }
}
