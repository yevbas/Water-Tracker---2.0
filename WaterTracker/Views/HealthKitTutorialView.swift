//
//  HealthKitTutorialView.swift
//  WaterTracker
//
//  Created by Assistant on 02/10/2025.
//

import SwiftUI

struct HealthKitTutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    
    private let pages = [
        TutorialPage(
            title: String(localized: "Connect Your Health Data"),
            subtitle: String(localized: "Unlock Personalized Hydration"),
            description: String(localized: "HealthKit integration allows WaterTracker to access your health metrics like height, weight, age, and sleep data to provide personalized hydration recommendations."),
            icon: "heart.fill",
            iconColor: .red,
            benefits: [
                String(localized: "Personalized daily water goals based on your body metrics"),
                String(localized: "Automatic calculation of optimal hydration levels"),
                String(localized: "Sleep quality analysis with hydration correlation"),
                String(localized: "Sync your water intake data to the Health app")
            ]
        ),
        TutorialPage(
            title: String(localized: "Why HealthKit Integration?"),
            subtitle: String(localized: "Science-Based Recommendations"),
            description: String(localized: "Your hydration needs depend on your individual characteristics. By connecting HealthKit, we can calculate your optimal water intake using proven formulas."),
            icon: "brain.head.profile",
            iconColor: .blue,
            benefits: [
                String(localized: "Body weight affects how much water you need daily"),
                String(localized: "Age and gender influence hydration requirements"),
                String(localized: "Sleep patterns show how hydration affects rest quality"),
                String(localized: "Activity levels determine additional water needs")
            ]
        ),
        TutorialPage(
            title: String(localized: "What Data We Use"),
            subtitle: String(localized: "Privacy & Transparency"),
            description: String(localized: "We only access the health data you explicitly allow. All calculations happen on your device, and your data never leaves your iPhone."),
            icon: "lock.shield.fill",
            iconColor: .green,
            benefits: [
                String(localized: "Height & Weight: For personalized hydration formulas"),
                String(localized: "Age & Gender: For metabolic rate adjustments"),
                String(localized: "Sleep Data: To optimize hydration timing"),
                String(localized: "Activity Data: For exercise-based recommendations")
            ]
        ),
        TutorialPage(
            title: String(localized: "Getting Started"),
            subtitle: String(localized: "Enable HealthKit in Settings"),
            description: String(localized: "Go to Settings → Health & Data to connect HealthKit. You can choose which data to share and modify permissions anytime in the Health app."),
            icon: "gearshape.fill",
            iconColor: .purple,
            benefits: [
                String(localized: "Tap 'Enable HealthKit' in the Health & Data card"),
                String(localized: "Grant permissions for the data you want to share"),
                String(localized: "Your personalized recommendations will appear instantly"),
                String(localized: "Modify permissions anytime in the Health app")
            ]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Page Content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    HKTutorialPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Bottom Navigation
            VStack(spacing: 20) {
                // Page Indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? .red : .gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                
                // Navigation Buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button("Previous") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage -= 1
                            }
                        }
                        .foregroundStyle(.secondary)
                    } else {
                        Spacer()
                    }
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button("Next") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPage += 1
                            }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                        } else {
                            Button("Done") {
                                dismiss()
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle("HealthKit Tutorial")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

struct TutorialPage {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let iconColor: Color
    let benefits: [String]
}

struct HKTutorialPageView: View {
    let page: TutorialPage
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Icon and Title
                VStack(spacing: 20) {
                    Image(systemName: page.icon)
                        .font(.system(size: 60, weight: .medium))
                        .foregroundStyle(page.iconColor)
                        .frame(width: 100, height: 100)
                        .background(
                            Circle()
                                .fill(page.iconColor.opacity(0.1))
                        )
                    
                    VStack(spacing: 8) {
                        Text(page.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(page.subtitle)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Description
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                // Benefits List
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(page.benefits, id: \.self) { benefit in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(page.iconColor)
                                .font(.system(size: 16))
                                .frame(width: 20, height: 20)
                            
                            Text(benefit)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(page.iconColor.opacity(0.2), lineWidth: 1)
                        )
                )
                
                Spacer(minLength: 50)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    HealthKitTutorialView()
}
