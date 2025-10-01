//
//  HealthKitCard.swift
//  WaterTracker
//
//  Created by Jackson  on 10/09/2025.
//

import SwiftUI
import HealthKit

struct HealthKitCard: View {
    @EnvironmentObject private var healthKitService: HealthKitService
    @State private var isRequestingHealthKitPermission = false
    @State private var showingHealthKitAlert = false
    @State private var healthKitAlertMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.white)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            colors: [.red, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Health & Data")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Text("Connect with HealthKit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            VStack(spacing: 16) {
                Button {
                    isRequestingHealthKitPermission = true
                } label: {
                    HStack {
                        Image(systemName: "heart.text.square")
                            .foregroundStyle(.white)
                            .font(.system(size: 16))
                        Text("Request HealthKit Access")
                            .foregroundStyle(.white)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.red, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Text("Grant HealthKit permission to get personalized hydration recommendations based on your health data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .red.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .healthDataAccessRequest(
            store: healthKitService.healthStore,
            readTypes: healthKitService.healthKitTypes,
            trigger: isRequestingHealthKitPermission
        ) { result in
            handleHealthKitPermissionResult(result)
        }
        .alert("HealthKit", isPresented: $showingHealthKitAlert) {
            Button("OK") { }
        } message: {
            Text(healthKitAlertMessage)
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleHealthKitPermissionResult(_ result: Result<Bool, Error>) {
        isRequestingHealthKitPermission = false
        
        switch result {
        case .success:
            healthKitAlertMessage = "HealthKit access granted. Your health data can now be used for personalized hydration recommendations."
        case .failure(let error):
            healthKitAlertMessage = "Failed to access HealthKit: \(error.localizedDescription)"
        }
        showingHealthKitAlert = true
    }
}

#Preview {
    HealthKitCard()
        .environmentObject(HealthKitService())
        .padding()
}
