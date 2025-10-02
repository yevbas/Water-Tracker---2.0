//
//  DrinkAnalysisView.swift
//  WaterTracker
//
//  Created by Jackson  on 11/06/2025.
//

import SwiftUI
import UIKit
import RevenueCatUI

struct DrinkAnalysisView: View {
    @EnvironmentObject private var analysisClient: AIDrinkAnalysisClient
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var analysisResult: DrinkAnalysisResult?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isPresentedPaywall = false

    @EnvironmentObject var revenueCatMonitor: RevenueCatMonitor

    @AppStorage("measurement_units") private var measurementUnitsString: String = "ml"
    
    private var measurementUnits: WaterUnit {
        get { WaterUnit.fromString(measurementUnitsString) }
        set { measurementUnitsString = newValue == .ounces ? "fl_oz" : "ml" }
    }
    
    var onDrinkAnalyzed: (Drink, Double) -> Void = { _, _ in }
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                if analysisResult == nil {
                    VStack(spacing: 12) {
                        Text("Analyze Your Drink")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text("Take a photo or select from library to automatically detect the drink type and volume")
                            .font(.system(.callout, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            showingCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                            }
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.blue)
                            }
                        }
                        
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choose from Library")
                            }
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.blue, lineWidth: 2)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    // Show analysis result
                    VStack(spacing: 16) {
                        Text("Analysis Complete!")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.green)
                        
                        VStack(spacing: 12) {
                            Text(analysisResult?.drink.emoji ?? "")
                                .font(.system(size: 60))
                            
                            Text(analysisResult?.drink.title ?? "")
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                            
                            Text("\(analysisResult?.amount.formatted() ?? "0") \(measurementUnits.shortName)")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(.blue)
                        }
                        .padding(20)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        }
                        
                        HStack(spacing: 12) {
                            Button("Analyze Another") {
                                resetAnalysis()
                            }
                            .font(.system(.callout, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            
                            Button("Add This Drink") {
                                if let result = analysisResult {
                                    onDrinkAnalyzed(result.drink, result.amount)
                                    dismiss()
                                }
                            }
                            .font(.system(.callout, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.vertical, 16)
            
            // Loading overlay
            if analysisClient.isAnalyzing {
                DrinkAnalysisLoaderView()
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            PhotoLibraryPicker(image: $selectedImage)
        }
        .sheet(isPresented: $showingCamera) {
            CameraPhotoPicker(image: $selectedImage)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $isPresentedPaywall) {
            PaywallView()
        }
        .alert("Analysis Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage, revenueCatMonitor.userHasFullAccess {
                analyzeImage(image)
            } else {
                isPresentedPaywall = true
            }
        }
    }
    
    private func analyzeImage(_ image: UIImage) {
        Task {
            // Show full screen ad before analyzing
            await FullScreenAdService.shared.showAd()
            
            do {
                let result = try await analysisClient.analyzeDrink(
                    image: image,
                    measurementUnits: measurementUnits
                )
                
                await MainActor.run {
                    analysisResult = result
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func resetAnalysis() {
        analysisResult = nil
        selectedImage = nil
    }
}

#Preview {
    DrinkAnalysisView()
}
