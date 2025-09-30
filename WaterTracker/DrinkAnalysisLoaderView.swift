//
//  DrinkAnalysisLoaderView.swift
//  WaterTracker
//
//  Created by Jackson  on 11/06/2025.
//

import SwiftUI
import Lottie

struct DrinkAnalysisLoaderView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Lottie animation
            LottieView(animation: .named("h2o-rocket"))
                .playing(.fromProgress(0.0, toProgress: 1.0, loopMode: .loop))
                .animationSpeed(1.0)
                .frame(width: 150, height: 150)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            
            VStack(spacing: 8) {
                Text("Analyzing your drink...")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("Please wait while we identify the drink and estimate the volume")
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
        .padding(.horizontal, 24)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    DrinkAnalysisLoaderView()
}
