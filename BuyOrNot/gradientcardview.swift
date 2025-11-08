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
        ZStack(alignment: .topLeading) {
            // 背景
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(colors: colors,
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
            
            // 左上角图标
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: systemImage)
                        .foregroundStyle(.purple)
                        .font(.system(size: 20, weight: .bold))
                )
                .padding(.top, 14)
                .padding(.leading, 14)
            
            // 文本
            VStack(alignment: .leading, spacing: 4) {
                Spacer().frame(height: 60)   // 给图标让位置
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.black.opacity(0.8))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.black.opacity(0.5))
                }
                Spacer()
            }
            .padding(14)
        }
        // 固定高度让两个卡片对齐
        .frame(height: 150)
    }
}
