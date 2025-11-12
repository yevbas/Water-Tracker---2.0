//
//  CitationsView.swift
//  WaterTracker
//
//  Created by Assistant on 02/10/2025.
//

import SwiftUI

struct MedicalCitation {
    let title: String
    let source: String
    let url: String
}

struct CitationsView: View {
    let citations: [MedicalCitation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text("Medical Information Sources")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(citations.enumerated()), id: \.offset) { index, citation in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(citation.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Text(citation.source)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Link(destination: URL(string: citation.url)!) {
                            HStack(spacing: 4) {
                                Text("View Source")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.secondary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    CitationsView(citations: [
        MedicalCitation(
            title: "Daily Water Intake Recommendations",
            source: "National Academies of Sciences, Engineering, and Medicine",
            url: "https://www.nap.edu/catalog/10925/dietary-reference-intakes-for-water-potassium-sodium-chloride-and-sulfate"
        )
    ])
    .padding()
}

