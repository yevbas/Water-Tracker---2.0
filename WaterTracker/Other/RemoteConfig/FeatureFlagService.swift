//
//  FeatureFlagService.swift
//  Weeshlist
//
//  Created by Jackson  on 07/05/2025.
//

import Foundation

final class FeatureFlagService {
    static let shared = FeatureFlagService()

    private init() {}

    func isEnabled(_ featureFlag: RemoteConfigBooleanKey) -> Bool {
        RemoteConfigService.shared.bool(featureFlag)
    }
}
