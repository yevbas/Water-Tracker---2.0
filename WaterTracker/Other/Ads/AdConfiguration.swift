//
//  AdMobBannerConfiguration.swift
//  Leafy
//
//  Created by Jackson  on 27/06/2025.
//

import Foundation

struct AdConfiguration: Decodable {
    let fullscreen: FullScreen
    let banners: Banners

    struct FullScreen: Decodable {
        let createScreen: String
    }

    struct Banners: Decodable {
        let mainScreen: String
        let editScreen: String
    }
}
