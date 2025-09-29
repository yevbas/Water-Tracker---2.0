//
//  PrimaryButton.swift
//  PlateAI
//
//  Created by Jackson  on 06/11/2024.
//

import SwiftUI

struct PrimaryButton: View {
    var title: String = "Button"
    var systemImage: String?

    var borderColors: [Color]?
    var borderWidth: CGFloat = 1.0

    var colors: [Color] = [.primary]
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(
            action: action,
            label: {
                Group {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.horizontal, 32)
                    } else if let systemImage {
                        Label(title, systemImage: systemImage)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.primary)
                            .colorInvert()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(title)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.primary)
                            .colorInvert()
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 56)
                .background {
                    Group {
                        if isLoading {
                            Circle()
                                .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                        } else {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
                        }
                    }
                }
                .overlay {
                    if let borderColors {
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(LinearGradient(colors: borderColors, startPoint: .leading, endPoint: .trailing), lineWidth: borderWidth)
                    }
                }
                .opacity(isDisabled ? 0.5 : 1.0)
            }
        )
        .disabled(isDisabled || isLoading)
        .animation(.default, value: isLoading)
    }
}

#Preview {
    VStack {
        PrimaryButton(
            title: "Preview",
            colors: [.blue, .purple, .pink],
            isLoading: true,
            action: {}
        )
        PrimaryButton(
            title: "Preview",
            colors: [.blue, .purple, .pink],
            isLoading: false,
            isDisabled: true,
            action: {}
        )
    }
    .padding(.horizontal, 16)
}
