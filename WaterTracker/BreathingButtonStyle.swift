//
//  BreathingButtonStyle.swift
//  WaterTracker
//
//  Created by Jackson  on 21/11/2025.
//

import SwiftUI
import Lottie

struct BreathingButtonStyle: ButtonStyle {
    var zoomMultiplier = 1.08
    var animationDuration = 0.75

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .phaseAnimator([1, zoomMultiplier]) { view, value in
                view.scaleEffect(
                    x: value,
                    y: value
                )
            } animation: { value in
                return .easeOut(duration: animationDuration)
            }
            .opacity(configuration.isPressed ? 0.5 : 1)
            .scaleEffect(x: configuration.isPressed ? zoomMultiplier : 1, y: configuration.isPressed ? zoomMultiplier : 1)
    }
}
