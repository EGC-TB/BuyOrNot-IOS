import SwiftUI

struct RootView: View {
    @State private var showNewDecision = false
    @State private var showExpenseTracker = false
    @State private var showAccount = false
    
    // 当前要聊天的决策
    @State private var activeDecision: Decision? = nil
    
    @State private var decisions: [Decision] = [
        .init(id: UUID(), title: "Iphone 17 pro", price: 1500, date: .now, status: .skipped)
    ]
    
    @State private var expenses: [ExpenseItem] = [
        .init(id: UUID(), name: "MacBook Pro", price: 1500, date: .now),
        .init(id: UUID(), name: "Tesla Model 3", price: 24000, date: .now),
        .init(id: UUID(), name: "Iphone 15", price: 1200, date: .now),
    ]
    
    var body: some View {
        NavigationStack {
            DashboardView(
                decisions: decisions,
                expenses: expenses,
                onNewDecision: { showNewDecision = true },
                onShowExpenses: { showExpenseTracker = true },
                onAvatarTap: { showAccount = true },
                onDecisionTapForChat: { decision in
                    activeDecision = decision
                }
            )
            .sheet(isPresented: $showNewDecision) {
                DecisionFormView { newDecision in
                    // 新建决策后，先加到列表中，然后进入chat
                    decisions.insert(newDecision, at: 0)
                    activeDecision = newDecision
                }
            }
            .sheet(isPresented: $showExpenseTracker) {
                ExpenseTrackerView(expenses: $expenses)
            }
            .sheet(isPresented: $showAccount) {
                AccountView()
            }
            .sheet(item: $activeDecision) { decision in
                ChatBotView(
                    decision: decision,
                    onBuy: { updated in
                        // 如果已有这条，就更新状态；没有就加进去
                        if let idx = decisions.firstIndex(where: { $0.id == updated.id }) {
                            decisions[idx] = updated
                        } else {
                            decisions.insert(updated, at: 0)
                        }
                    },
                    onSkip: { updated in
                        if let idx = decisions.firstIndex(where: { $0.id == updated.id }) {
                            decisions[idx] = updated
                        } else {
                            decisions.insert(updated, at: 0)
                        }
                    }
                )
            }
        }
    }
}
