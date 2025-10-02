//
//  InterstitialAdService.swift
//  Leafy
//
//  Created by Jackson  on 27/06/2025.
//

import Foundation
import GoogleMobileAds

final class FullScreenAdService: NSObject, FullScreenContentDelegate {
    static let shared = FullScreenAdService()

    private var interstitialAd: InterstitialAd?

    private var dismissalContinuation: CheckedContinuation<Void, Never>?

    func loadAd() async {
        do {
#if DEBUG
            // Test id
            interstitialAd = try await InterstitialAd.load(
                with: "ca-app-pub-3940256099942544/4411468910", request: Request())
#else
            // fetch ids from remote-config
            guard let config: AdConfiguration = RemoteConfigService.shared.model(.adMobConfig) else {
                throw GeneralError.somethingWrong
            }
            interstitialAd = try await InterstitialAd.load(
                with: config.fullscreen.createScreen,
                request: Request()
            )
#endif
            interstitialAd?.fullScreenContentDelegate = self
        } catch {
            print("Failed to load interstitial ad with error: \(error.localizedDescription)")
        }
    }

    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Failed to present ad: \(error.localizedDescription)")
    }


    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")
    }

    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")

        interstitialAd = nil
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("\(#function) called")

        // Resume the continuation to allow presentAd to finish
        dismissalContinuation?.resume()
        dismissalContinuation = nil

        Task { await loadAd() }
    }

    func showAd() async {
        guard let interstitialAd = interstitialAd else {
            print("❌ Ad wasn't loaded.")
            return
        }

        guard let rootViewController = await getTopViewController() else {
            print("❌ Failed to find top view controller.")
            return
        }

        print("🔍 Ad ready: \(interstitialAd.responseInfo != nil)")
        print("🔍 Attempting to present from: \(type(of: rootViewController))")

        do {
            try await interstitialAd.canPresent(from: rootViewController)

            await withCheckedContinuation { [weak self] continuation in
                self?.dismissalContinuation = continuation

                DispatchQueue.main.async {
                    print("✅ Presenting interstitial ad.")

                    interstitialAd.present(from: rootViewController)
                }
            }
        } catch {
            print("⚠️ Ad cannot be presented from this root view controller.")

            dismissalContinuation = nil
        }
    }


    private func getTopViewController() async -> UIViewController? {
        await MainActor.run {
            guard let keyWindow = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }),
                  let root = keyWindow.rootViewController else {
                return nil
            }

            return findTopViewController(from: root)
        }
    }

    private func findTopViewController(from vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return findTopViewController(from: presented)
        }
        if let nav = vc as? UINavigationController, let top = nav.visibleViewController {
            return findTopViewController(from: top)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return findTopViewController(from: selected)
        }
        return vc
    }

}

enum GeneralError: Error {
    case somethingWrong
}
