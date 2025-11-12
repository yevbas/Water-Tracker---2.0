//
//  WeatherAttribution.swift
//  WaterTracker
//
//  Created by Jackson  on 12/11/2025.
//

import SwiftUI
import WeatherKit

struct WeatherAttribution: View {
    @Environment(\.colorScheme) var colorScheme
    @State var attribution: WeatherKit.WeatherAttribution?

    var body: some View {
        VStack {
            if let attribution {
                AsyncImage(url: colorScheme == .dark ? attribution.combinedMarkDarkURL : attribution.combinedMarkLightURL) { image in
                    image
                        .image?
                        .resizable()
                        .scaledToFit()
                        .frame(height: 11)
                }
            } else {
                ProgressView()
            }
            Link(destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!) {
                Text(verbatim: "Apple Weather")
                    .font(.system(size: 11))
            }
        }
        .task {
            Task.detached { @MainActor in
                let attribution = try? await WeatherKit.WeatherService.shared.attribution

                self.attribution = attribution
            }
        }
    }
}

#Preview {
    WeatherAttribution()
}
