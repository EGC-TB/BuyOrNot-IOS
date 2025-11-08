import SwiftUI

struct DashboardView: View {
    let decisions: [Decision]
    let expenses: [ExpenseItem]
    let savedAmount: Double
    let userName: String
    
    var onNewDecision: () -> Void
    var onShowExpenses: () -> Void
    var onAvatarTap: () -> Void
    var onDecisionTapForChat: (Decision) -> Void
    
    private var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.price }
    }
    
    // 头像首字母
    private var initials: String {
        let parts = userName.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 👇 用系统安全区而不是 Environment key
                    Color.clear
                        .frame(height: 8) // 给一点顶部间距
                    
                    header
                    
                    Text("My Decisions")
                        .font(.title2).bold()
                        .foregroundStyle(Color.primary)
                    
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
                                    Color.purple,
                                    Color.pink
                                ]
                            )
                        }
                        
                        Button { onShowExpenses() } label: {
                            GradientCardView(
                                title: "Expenses",
                                subtitle: "\(expenses.count) items",
                                systemImage: "dollarsign",
                                colors: [
                                    Color.green,
                                    Color.mint
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
                .padding(.top, 16) // 再给一点总的上边距，防止贴刘海
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
                Text("BuyOrNot")
                    .font(.title3).bold()
                    .foregroundStyle(Color.primary)
            }
            
            Spacer()
            
            Button {
                onAvatarTap()
            } label: {
                Circle()
                    .fill(
                        LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(initials)
                            .font(.footnote).bold()
                            .foregroundStyle(.white)
                    )
                    .shadow(color: Color.primary.opacity(0.08), radius: 5, x: 0, y: 4)
            }
        }
    }
}
