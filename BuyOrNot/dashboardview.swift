import SwiftUI

struct DashboardView: View {
    let decisions: [Decision]
    let expenses: [ExpenseItem]
    let savedAmount: Double      // ✅ 新增
    let userName: String
    var onNewDecision: () -> Void
    var onShowExpenses: () -> Void
    var onAvatarTap: () -> Void
    var onDecisionTapForChat: (Decision) -> Void
    
    private var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.price }
    }
    
    private var initials: String {
        let parts = userName.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [
                Color(red: 0.97, green: 0.92, blue: 1.0),
                Color(red: 0.88, green: 0.93, blue: 1.0)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    
                    Text("My Decisions")
                        .font(.title2).bold()
                        .foregroundStyle(.black.opacity(0.8))
                    
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Spent")
                                .font(.caption)
                                .foregroundStyle(.gray)
                            Text("$\(totalSpent, specifier: "%.2f")")
                                .font(.title3).bold()
                                .foregroundStyle(.green)
                        }
                        
                        Divider()
                            .frame(height: 32)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Saved")
                                .font(.caption)
                                .foregroundStyle(.gray)
                            Text("$\(savedAmount, specifier: "%.2f")")
                                .font(.title3).bold()
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, 8)
                    
                    HStack(alignment: .top, spacing: 20) {
                        Button { onNewDecision() } label: {
                            GradientCardView(
                                title: "New Decision",
                                systemImage: "plus",
                                colors: [
                                    Color(red: 0.95, green: 0.88, blue: 1.0),
                                    Color(red: 0.87, green: 0.84, blue: 1.0)
                                ]
                            )
                        }
                        
                        Button { onShowExpenses() } label: {
                            GradientCardView(
                                title: "Expenses",
                                subtitle: "\(expenses.count) items",
                                systemImage: "dollarsign",
                                colors: [
                                    Color(red: 0.84, green: 0.99, blue: 0.90),
                                    Color(red: 0.78, green: 0.93, blue: 0.85)
                                ]
                            )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(decisions) { decision in
                            DecisionCardView(decision: decision) {
                                onDecisionTapForChat(decision)
                            }
                        }
                    }
                    .padding(.top, 4)
                    
                    Spacer(minLength: 50)
                }
                .padding(.horizontal, 22)
                .padding(.top, 10)
            }
        }
    }
    
    private var header: some View {
        HStack {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: "bag")
                        .foregroundStyle(.white)
                        .font(.system(size: 20, weight: .bold))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("BuyOrNot")
                        .font(.title3).bold()
                        .foregroundStyle(.black.opacity(0.8))
                }
            }
            Spacer()
            Button {
                onAvatarTap()
            } label: {
                Circle()
                    .fill(
                        LinearGradient(colors: [.purple, .pink],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(initials)
                            .font(.footnote).bold()
                            .foregroundStyle(.white)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 4)
            }
        }
    }
}
