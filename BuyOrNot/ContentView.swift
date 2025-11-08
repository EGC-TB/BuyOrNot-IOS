import SwiftUI

struct RootView: View {
    // 弹窗控制
    @State private var showNewDecision = false
    @State private var showExpenseTracker = false
    @State private var showAccount = false
    @State private var activeDecision: Decision? = nil
    
    // 用户信息（和头像字母绑定）
    @State private var userName: String = "Eagle Chen"
    @State private var userEmail: String = "eagle.chen@example.com"
    
    // 决策列表
    @State private var decisions: [Decision] = [
        Decision(id: UUID(), title: "Iphone 17 Pro", price: 1500, date: .now, status: .skipped),
        Decision(id: UUID(), title: "Porsche 911", price: 150000, date: .now, status: .pending)
    ]
    
    // 消费列表
    @State private var expenses: [ExpenseItem] = [
        ExpenseItem(id: UUID(),
                    decisionId: nil,
                    name: "MacBook Pro",
                    price: 1500,
                    date: .now)
    ]
    
    // 省下来的钱
    @State private var savedAmount: Double = 0
    
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
            // 新建决策
            .sheet(isPresented: $showNewDecision) {
                DecisionFormView { newDecision in
                    decisions.insert(newDecision, at: 0)
                    activeDecision = newDecision
                }
            }
            // 支出页面
            .sheet(isPresented: $showExpenseTracker) {
                ExpenseTrackerView(expenses: $expenses)
            }
            // 账号页
            .sheet(isPresented: $showAccount) {
                AccountView(
                    name: $userName,
                    email: $userEmail,
                    decisionsCount: decisions.count,
                    savedAmount: savedAmount,
                    spentAmount: expenses.reduce(0) { $0 + $1.price }
                )
            }
            // 聊天页
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
        }
    }
    
    // MARK: - 入口：chat 回来的时候走这里
    private func applyDecisionChange(_ updated: Decision, newStatus: Decision.Status) {
        if let idx = decisions.firstIndex(where: { $0.id == updated.id }) {
            let oldDecision = decisions[idx]
            var newDecision = updated
            newDecision.status = newStatus
            decisions[idx] = newDecision
            reconcile(old: oldDecision, new: newDecision)
        } else {
            // 列表里没有，就是新加的
            var newDecision = updated
            newDecision.status = newStatus
            decisions.insert(newDecision, at: 0)
            reconcile(old: nil, new: newDecision)
        }
    }
    
    // MARK: - 真正的“差量更新”逻辑
    private func reconcile(old: Decision?, new: Decision) {
        let price = new.price
        
        switch (old?.status, new.status) {
            
        // 1. 新的 / pending -> 买了
        case (.none, .purchased),
             (.some(.pending), .purchased):
            addExpense(for: new)
            
        // 2. 新的 / pending -> 不买
        case (.none, .skipped),
             (.some(.pending), .skipped):
            savedAmount += price
            
        // 3. 买了 -> 不买 （把之前的支出删掉，再把钱加到 saved）
        case (.some(.purchased), .skipped):
            removeExpense(matching: new)
            savedAmount += price
            
        // 4. 不买 -> 买了 （把 saved 里对应的钱减掉，再加支出）
        case (.some(.skipped), .purchased):
            if savedAmount >= price {
                savedAmount -= price
            } else {
                savedAmount = 0
            }
            addExpense(for: new)
            
        // 其它情况：买 -> 买、 不买 -> 不买
        default:
            break
        }
    }
    
    // MARK: - 加消费
    private func addExpense(for decision: Decision) {
        let item = ExpenseItem(
            id: UUID(),
            decisionId: decision.id,   // 👈 关键：记住是这条 decision 产生的
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
            // fallback，防止旧数据没有 decisionId
            expenses.remove(at: idx)
        }
    }
}
