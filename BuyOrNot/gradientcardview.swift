//
//  gradientcardview.swift
//  BuyOrNot
//
//  Created by Eagle Chen on 11/7/25.
//

import SwiftUI

struct GradientCardView: View {
    var title: String
    var subtitle: String? = nil
    var systemImage: String
    var colors: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 60, height: 60)
                Image(systemName: systemImage)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.purple)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.black.opacity(0.8))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 160)
        .background(
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(30)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}
