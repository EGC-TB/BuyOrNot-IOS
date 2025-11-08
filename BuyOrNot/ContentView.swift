import SwiftUI

struct RootView: View {
    // 弹窗
    @State private var showNewDecision = false
    @State private var showExpenseTracker = false
    @State private var showAccount = false
    @State private var activeDecision: Decision? = nil
    
    // 用户
    @State private var userName: String = "Eagle Chen"
    @State private var userEmail: String = "eagle.chen@example.com"
    
    // 初始决策（可以有已经 skipped 的）
    @State private var decisions: [Decision] = [
        Decision(id: UUID(), title: "Iphone 17 Pro", price: 1500, date: .now, status: .skipped),
        Decision(id: UUID(), title: "Porsche 911", price: 150000, date: .now, status: .skipped)
    ]
    
    // 初始支出
    @State private var expenses: [ExpenseItem] = [
        ExpenseItem(id: UUID(),
                    decisionId: nil,
                    name: "MacBook Pro",
                    price: 1500,
                    date: .now)
    ]
    
    // 省下的钱（我们会在 onAppear 里重新算一遍）
    @State private var savedAmount: Double = 0
    
    // 为了避免 onAppear 多次执行导致重复结算
    @State private var didInitReconcile: Bool = false
    
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
                AccountView(
                    name: $userName,
                    email: $userEmail,
                    decisionsCount: decisions.count,
                    savedAmount: savedAmount,
                    spentAmount: expenses.reduce(0) { $0 + $1.price }
                )
            }
            .sheet(item: $activeDecision) { decision in
                ChatBotView(
                    decision: decision,
                    onBuy: { updated in
                        applyDecisionChange(updated, newStatus: .purchased)
                    },
                    onSkip: { updated in
                        applyDecisionChange(updated, newStatus: .skipped)
                    }
                )
            }
            // 👇 初始化结算：只做一次
            .onAppear {
                if !didInitReconcile {
                    initialReconcile()
                    didInitReconcile = true
                }
            }
        }
    }
    
    // MARK: - 初次启动时，把现有的数据“算一遍”
    private func initialReconcile() {
        // 1. 把所有 skipped 的决策加进 saved
        let skippedTotal = decisions
            .filter { $0.status == .skipped }
            .reduce(0.0) { $0 + $1.price }
        savedAmount += skippedTotal
        
        // 2. 如果你想保证所有 purchased 的决策都有对应的 expense，可以补齐
        for decision in decisions where decision.status == .purchased {
            // 如果已经有这条 decision 的消费，就不重复加
            let alreadyExists = expenses.contains { $0.decisionId == decision.id }
            if !alreadyExists {
                addExpense(for: decision)
            }
        }
    }
    
    // MARK: - Chat 回来的入口
    private func applyDecisionChange(_ updated: Decision, newStatus: Decision.Status) {
        if let idx = decisions.firstIndex(where: { $0.id == updated.id }) {
            let oldDecision = decisions[idx]
            var newDecision = updated
            newDecision.status = newStatus
            decisions[idx] = newDecision
            reconcile(old: oldDecision, new: newDecision)
        } else {
            var newDecision = updated
            newDecision.status = newStatus
            decisions.insert(newDecision, at: 0)
            reconcile(old: nil, new: newDecision)
        }
    }
    
    // MARK: - 差量更新
    private func reconcile(old: Decision?, new: Decision) {
        let price = new.price
        
        switch (old?.status, new.status) {
        // 新的 / pending -> 买了
        case (.none, .purchased),
             (.some(.pending), .purchased):
            addExpense(for: new)
            
        // 新的 / pending -> 不买
        case (.none, .skipped),
             (.some(.pending), .skipped):
            savedAmount += price
            
        // 买了 -> 不买
        case (.some(.purchased), .skipped):
            removeExpense(matching: new)
            savedAmount += price
            
        // 不买 -> 买了
        case (.some(.skipped), .purchased):
            if savedAmount >= price {
                savedAmount -= price
            } else {
                savedAmount = 0
            }
            addExpense(for: new)
            
        default:
            break
        }
    }
    
    // MARK: - 加消费
    private func addExpense(for decision: Decision) {
        let item = ExpenseItem(
            id: UUID(),
            decisionId: decision.id,
            name: decision.title,
            price: decision.price,
            date: .now
        )
        expenses.insert(item, at: 0)
    }
    
    // MARK: - 删消费
    private func removeExpense(matching decision: Decision) {
        if let idx = expenses.firstIndex(where: { $0.decisionId == decision.id }) {
            expenses.remove(at: idx)
        } else if let idx = expenses.firstIndex(where: { $0.name == decision.title && $0.price == decision.price }) {
            expenses.remove(at: idx)
        }
    }
}
