import SwiftUI

struct RootView: View {
    @State private var showNewDecision = false
    @State private var showExpenseTracker = false
    @State private var showAccount = false
    @State private var activeDecision: Decision? = nil

    // 这些是你真正想绑定的用户信息
    @State private var userName: String = "Jane Doe"
    @State private var userEmail: String = "jane.doe@example.com"
    
    @State private var decisions: [Decision] = [
        .init(id: UUID(), title: "Iphone 17 pro", price: 1500, date: .now, status: .skipped)
    ]
    
    @State private var expenses: [ExpenseItem] = [
        .init(id: UUID(), name: "MacBook Pro", price: 1500, date: .now),
        .init(id: UUID(), name: "Tesla Model 3", price: 24000, date: .now),
        .init(id: UUID(), name: "Iphone 15", price: 1200, date: .now),
    ]
    
    @State private var savedAmount: Double = 0
    
    private var totalSpent: Double {
        expenses.reduce(0) { $0 + $1.price }
    }
    
    var body: some View {
        NavigationStack {
            DashboardView(
                decisions: decisions,
                expenses: expenses,
                savedAmount: savedAmount,
                userName: userName,
                onNewDecision: { showNewDecision = true },
                onShowExpenses: { showExpenseTracker = true },
                onAvatarTap: { showAccount = true },
                onDecisionTapForChat: { decision in
                    activeDecision = decision
                }
            )
            .sheet(isPresented: $showNewDecision) {
                DecisionFormView { newDecision in
                    decisions.insert(newDecision, at: 0)
                    activeDecision = newDecision
                }
            }
            .sheet(isPresented: $showExpenseTracker) {
                ExpenseTrackerView(expenses: $expenses)
            }
            .sheet(isPresented: $showAccount) {
                // 👇 这里把绑定传进去
                AccountView(
                    name: $userName,
                    email: $userEmail,
                    decisionsCount: decisions.count,
                    savedAmount: savedAmount,
                    spentAmount: totalSpent
                )
            }
            .sheet(item: $activeDecision) { decision in
                ChatBotView(
                    decision: decision,
                    onBuy: { updated in
                        if let idx = decisions.firstIndex(where: { $0.id == updated.id }) {
                            decisions[idx] = updated
                        } else {
                            decisions.insert(updated, at: 0)
                        }
                        let item = ExpenseItem(id: UUID(), name: updated.title, price: updated.price, date: .now)
                        expenses.insert(item, at: 0)
                    },
                    onSkip: { updated in
                        if let idx = decisions.firstIndex(where: { $0.id == updated.id }) {
                            decisions[idx] = updated
                        } else {
                            decisions.insert(updated, at: 0)
                        }
                        savedAmount += updated.price
                    }
                )
            }
        }
    }
}
