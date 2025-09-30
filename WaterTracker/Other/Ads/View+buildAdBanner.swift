//
//  View+buildAdBanner.swift
//  Leafy
//
//  Created by Jackson  on 27/06/2025.
//

import SwiftUI
import GoogleMobileAds

extension View {
    @ViewBuilder
    func buildAdBannerView(
        _ banner: AdBannerView.Banner
    ) -> some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let adSize = currentOrientationAnchoredAdaptiveBanner(width: screenWidth)
            var bannerId: String {
#if DEBUG
                return "ca-app-pub-3940256099942544/2435281174"
#else
                return bannerId
#endif
            }
            AdBannerView(adSize, banner: banner)
                .frame(height: adSize.size.height)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Material.ultraThin)
                        ProgressView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        // Limit height of GeometryReader to banner height, so it doesn't expand unnecessarily
        .frame(height: currentOrientationAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width).size.height)
    }
}
