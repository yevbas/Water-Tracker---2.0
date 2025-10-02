//
//  GoogleAdBannerView.swift
//  Leafy
//
//  Created by Jackson  on 27/06/2025.
//

import Foundation
import GoogleMobileAds
import SwiftUI

struct AdBannerView: UIViewRepresentable {
    let adSize: AdSize
    let cornerRadius: CGFloat

    private let banner: Banner

    init(
        _ adSize: AdSize,
        cornerRadius: CGFloat = 12,
        banner: Banner
    ) {
        self.adSize = adSize
        self.cornerRadius = cornerRadius
        self.banner = banner
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.addSubview(context.coordinator.bannerView)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.bannerView.adSize = adSize
        context.coordinator.bannerView.layer.cornerRadius = cornerRadius
    }

    func makeCoordinator() -> BannerCoordinator {
        BannerCoordinator(self, banner: banner)
    }

    enum Banner {
        case mainScreen
        case editScreen
        case createScreen
        case addReminder

        var adUnitID: String? {
#if DEBUG
            return "ca-app-pub-3940256099942544/2435281174"
#else
            // fetch ids from remote-config
            guard let config: AdConfiguration = RemoteConfigService.shared.model(.adMobConfig) else {
                return nil
            }
            return switch self {
            case .mainScreen: config.banners.mainScreen
            case .editScreen: config.banners.editScreen
            case .createScreen: config.banners.createScreen
            case .addReminder: config.banners.addReminder
            }
#endif
        }
    }

    class BannerCoordinator: NSObject, BannerViewDelegate {
        private let banner: Banner

        private(set) lazy var bannerView: BannerView = {
            let view = BannerView(adSize: parent.adSize)
            view.adUnitID = banner.adUnitID
            view.load(Request())
            view.delegate = self
            return view
        }()

        let parent: AdBannerView

        init(_ parent: AdBannerView, banner: Banner) {
            self.parent = parent
            self.banner = banner
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
#if DEBUG
            NSLog(error.localizedDescription)
#endif
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            bannerView.alpha = 0
            UIView.animate(withDuration: 1, animations: {
                bannerView.alpha = 1
            })
        }

    }
}


