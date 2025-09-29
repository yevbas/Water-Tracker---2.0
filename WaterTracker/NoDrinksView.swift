//
//  NoDrinksView.swift
//  WaterTracker
//
//  Created by Jackson  on 19/09/2025.
//

import SwiftUI

struct NoDrinksView: View {
    var minHeight: CGFloat = 200

    var body: some View {
        Label("No drink found", systemImage: "magnifyingglass")
            .frame(
                maxWidth: .infinity,
                minHeight: minHeight,
                maxHeight: .infinity
            )
            .font(.title.weight(.medium))
    }
}

#Preview {
    NoDrinksView()
}
