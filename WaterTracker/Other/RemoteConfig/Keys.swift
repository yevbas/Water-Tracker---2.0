//
//  Keys.swift
//  Weeshlist
//
//  Created by Jackson  on 12/04/2025.
//

import Foundation

enum RemoteConfigBooleanKey: String {
    case mock
}

enum RemoteConfigStringKey: String {
    case openAIApiKey = "openai_api_key"
    case revenueCatAPIKey = "revenue_cat_api_key"
}

enum RemoteConfigJsonKey: String {
    case adMobConfig = "admob_config"
}

enum RemoteConfigNumberKey: String {
    case identificationsLimit = "identifications_limit"
}
