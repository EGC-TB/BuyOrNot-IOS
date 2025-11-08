//
//  decisioncardview.swift
//  BuyOrNot
//
//  Created by Eagle Chen on 11/7/25.
//

import SwiftUI

struct DecisionCardView: View {
    let decision: Decision
    var onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(colors: [
                            Color(red: 0.96, green: 0.75, blue: 0.80),
                            Color(red: 0.98, green: 0.70, blue: 0.75)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(height: 140)
                
                VStack(alignment: .leading, spacing: 10) {
                    if decision.status == .skipped {
                        Text("Saved")
                            .font(.caption2).bold()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    
                    Text(decision.title)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.95))
                    
                    Text("$\(decision.price, specifier: "%.2f")")
                        .font(.title3).bold()
                        .foregroundStyle(.white)
                    
                    Text(decision.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(16)
            }
        }
    }
}
