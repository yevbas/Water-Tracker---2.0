//
//  HealthKitPermissionView.swift
//  WaterTracker
//
//  Created by Assistant on 01/10/2025.
//

import SwiftUI
import HealthKit
import HealthKitUI
import SwiftData

struct HealthKitPermissionView: View {
    let onPermissionGranted: (UserHealthProfile?) -> Void
    let onPermissionDenied: () -> Void
    
    @State private var isRequestingHealthKitPermission = false
    @EnvironmentObject private var healthKitService: HealthKitService
    @Environment(\.modelContext) private var modelContext
    
    // HealthKit data properties
    @State private var userHeight: Double?
    @State private var userWeight: Double?
    @State private var userAge: Int?
    @State private var userGender: HKBiologicalSex?
    @State private var averageSleepHours: Double?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 12) {
                    // Health Icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.red.opacity(0.1), .pink.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 12) {
                        Text("Connect with Health")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)

                        Text("Get personalized hydration recommendations based on your health data")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)

                // Data Usage Cards
                VStack(spacing: 16) {
                    DataUsageCard(
                        icon: "person.crop.circle.fill",
                        title: "Age & Gender",
                        description: "Used to calculate your optimal daily water intake based on your body's needs",
                        gradientColors: [.red.opacity(0.1), .orange.opacity(0.1)]
                    )

                    DataUsageCard(
                        icon: "ruler.fill",
                        title: "Height & Weight",
                        description: "Helps determine your body's water requirements and hydration goals",
                        gradientColors: [.pink.opacity(0.1), .purple.opacity(0.1)]
                    )

                    DataUsageCard(
                        icon: "bed.double.fill",
                        title: "Sleep Data",
                        description: "Sleep quality affects hydration needs - we'll suggest adjustments based on your sleep patterns",
                        gradientColors: [.purple.opacity(0.1), .blue.opacity(0.1)]
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            // Action Buttons
            VStack(spacing: 16) {
                Button {
                    isRequestingHealthKitPermission = true
                } label: {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18, weight: .medium))

                        Text("Connect with Health")
                    }
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [.red, .red.opacity(0.8), .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                .disabled(isRequestingHealthKitPermission)

                Button {
                    onPermissionDenied()
                } label: {
                    Text("Skip for now")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .disabled(isRequestingHealthKitPermission)
            }
            .padding(.horizontal, 24)
        })
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .healthDataAccessRequest(
            store: healthKitService.healthStore,
            readTypes: healthKitService.healthKitTypes,
            trigger: isRequestingHealthKitPermission
        ) { result in
            switch result {
            case .success:
                // Permission granted - fetch data and create profile
                fetchHealthKitDataAndCreateProfile()
            case .failure:
                onPermissionDenied()
            }
        }
    }
    
    // MARK: - HealthKit Integration
    
    private func fetchHealthKitDataAndCreateProfile() {
        // Use the unified HealthKit data fetching method from HealthKitService
        healthKitService.fetchAllHealthData { profile in
            DispatchQueue.main.async {
                if let profile = profile, hasCompleteHealthKitData(from: profile) {
                    // Extract data from the profile for UI state
                    self.userHeight = profile.height
                    self.userWeight = profile.weight
                    self.userAge = profile.age
                    self.userGender = HKBiologicalSex.from(string: profile.gender)
                    self.averageSleepHours = profile.averageSleepHours
                    
                    // Save the profile to SwiftData
                    saveHealthDataToSwiftData()
                    
                    // Return the profile to the parent view
                    onPermissionGranted(profile)
                } else {
                    // Not enough data, create a basic profile with HealthKit enabled
                    let basicProfile = createBasicHealthKitProfile()
                    saveBasicProfileToSwiftData(basicProfile)
                    onPermissionGranted(basicProfile)
                }
            }
        }
    }
    
    private func hasCompleteHealthKitData(from profile: UserHealthProfile) -> Bool {
        return profile.height != nil &&
               profile.weight != nil &&
               profile.age != nil &&
               profile.gender != nil
    }
    
    private func createBasicHealthKitProfile() -> UserHealthProfile {
        return UserHealthProfile(
            height: nil,
            weight: nil,
            age: nil,
            gender: nil,
            isHealthKitEnabled: true,
            averageSleepHours: nil
        )
    }
    
    private func saveHealthDataToSwiftData() {
        print("📱 Saving HealthKit data to SwiftData from HealthKitPermissionView...")
        print("📱 Current data - height: \(userHeight ?? 0), weight: \(userWeight ?? 0), age: \(userAge ?? 0)")
        
        let averageSleepHours = self.averageSleepHours ?? 0
        
        let newProfile = UserHealthProfile(
            height: userHeight,
            weight: userWeight,
            age: userAge,
            gender: userGender?.stringValue,
            isHealthKitEnabled: true,
            averageSleepHours: averageSleepHours
        )
        
        modelContext.insert(newProfile)
        
        do {
            try modelContext.save()
            print("✅ HealthKit data saved to SwiftData with HealthKit enabled")
            
            // Verify the profile was saved
            let descriptor = FetchDescriptor<UserHealthProfile>()
            let profiles = try modelContext.fetch(descriptor)
            print("📱 Verification: Found \(profiles.count) profiles after save")
            if let savedProfile = profiles.first {
                print("📱 Saved profile - enabled: \(savedProfile.isHealthKitEnabled), height: \(savedProfile.height ?? 0)")
            }
        } catch {
            print("❌ Error saving HealthKit data to SwiftData: \(error)")
        }
    }
    
    private func saveBasicProfileToSwiftData(_ profile: UserHealthProfile) {
        print("📱 Saving basic HealthKit profile to SwiftData from HealthKitPermissionView...")
        
        modelContext.insert(profile)
        
        do {
            try modelContext.save()
            print("✅ Basic HealthKit profile saved to SwiftData")
        } catch {
            print("❌ Error saving basic HealthKit profile to SwiftData: \(error)")
        }
    }
}


struct DataUsageCard: View {
    let icon: String
    let title: String
    let description: String
    let gradientColors: [Color]
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.quaternary, lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    HealthKitPermissionPreviewView()
}

struct HealthKitPermissionPreviewView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 12) {
                    // Health Icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.red.opacity(0.1), .pink.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 64, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 12) {
                        Text("Connect with Health")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)

                        Text("Get personalized hydration recommendations based on your health data")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)

                // Data Usage Cards
                VStack(spacing: 16) {
                    DataUsageCard(
                        icon: "person.crop.circle.fill",
                        title: "Age & Gender",
                        description: "Used to calculate your optimal daily water intake based on your body's needs",
                        gradientColors: [.red.opacity(0.1), .orange.opacity(0.1)]
                    )

                    DataUsageCard(
                        icon: "ruler.fill",
                        title: "Height & Weight",
                        description: "Helps determine your body's water requirements and hydration goals",
                        gradientColors: [.pink.opacity(0.1), .purple.opacity(0.1)]
                    )

                    DataUsageCard(
                        icon: "bed.double.fill",
                        title: "Sleep Data",
                        description: "Sleep quality affects hydration needs - we'll suggest adjustments based on your sleep patterns",
                        gradientColors: [.purple.opacity(0.1), .blue.opacity(0.1)]
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            // Action Buttons
            VStack(spacing: 16) {
                Button {
                    print("Connect with Health tapped (Preview)")
                } label: {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18, weight: .medium))

                        Text("Connect with Health")
                    }
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [.red, .red.opacity(0.8), .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }

                Button {
                    print("Skip for now tapped (Preview)")
                } label: {
                    Text("Skip for now")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
        })
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
