import SwiftUI

struct RootView: View {
    @EnvironmentObject var authService: FirebaseService
    @StateObject private var dataManager = FirebaseDataManager()
    
    // 弹窗
    @State private var showNewDecision = false
    @State private var showExpenseTracker = false
    @State private var showAccount = false
    @State private var activeDecision: Decision? = nil
    
    // 用户
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    
    // 数据
    @State private var decisions: [Decision] = []
    @State private var expenses: [ExpenseItem] = []
    @State private var savedAmount: Double = 0
    
    // 加载状态
    @State private var isLoading: Bool = true
    @State private var hasLoadedInitialData: Bool = false
    
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
                    // 保存到Firebase
                    if let userId = authService.currentUserId {
                        Task {
                            try? await dataManager.saveDecision(newDecision, userId: userId)
                        }
                    }
                }
            }
            .sheet(isPresented: $showExpenseTracker) {
                ExpenseTrackerView(expenses: $expenses)
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showAccount) {
                AccountView(
                    name: $userName,
                    email: $userEmail,
                    decisionsCount: decisions.count,
                    savedAmount: savedAmount,
                    spentAmount: expenses.reduce(0) { $0 + $1.price }
                )
                .environmentObject(authService)
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
            .onAppear {
                if !hasLoadedInitialData {
                    loadInitialData()
                }
            }
            .onDisappear {
                dataManager.removeAllListeners()
            }
        }
    }
    
    // MARK: - Load Initial Data from Firebase
    // 加载初始数据
    private func loadInitialData() {
        guard let userId = authService.currentUserId else {
            isLoading = false
            return
        }
        
        Task {
            // 加载用户信息
            if let profile = try? await dataManager.loadUserProfile(userId: userId) {
                userName = profile.name
                userEmail = profile.email
            } else {
                // 如果 Firestore 中没有，尝试从 Auth 获取
                // 优先使用 displayName，如果没有则使用 email 的第一部分
                if let displayName = authService.currentUserName, !displayName.isEmpty {
                    userName = displayName
                } else if let email = authService.currentUserEmail {
                    // 如果 displayName 为空，使用邮箱的用户名部分（@ 之前的部分）
                    userName = String(email.split(separator: "@").first ?? "User")
                } else {
                    userName = "User"
                }
                userEmail = authService.currentUserEmail ?? ""
                
                // 保存到 Firestore，确保下次加载时能正确获取
                if !userName.isEmpty && !userEmail.isEmpty {
                    try? await dataManager.saveUserProfile(name: userName, email: userEmail, userId: userId)
                }
            }
            
            // 加载省下的金额
            savedAmount = (try? await dataManager.loadSavedAmount(userId: userId)) ?? 0.0
            
            // 设置实时监听
            dataManager.listenToDecisions(userId: userId) { [self] updatedDecisions in
                self.decisions = updatedDecisions.sorted { $0.date > $1.date }
                // 重新计算省下的金额
                recalculateSavedAmount()
            }
            
            dataManager.listenToExpenses(userId: userId) { [self] updatedExpenses in
                self.expenses = updatedExpenses.sorted { $0.date > $1.date }
            }
            
            isLoading = false
            hasLoadedInitialData = true
        }
    }
    
    // 重新计算省下的金额
    private func recalculateSavedAmount() {
        let skippedTotal = decisions
            .filter { $0.status == .skipped }
            .reduce(0.0) { $0 + $1.price }
        savedAmount = skippedTotal
        // 保存到Firebase
        if let userId = authService.currentUserId {
            Task {
                try? await dataManager.saveSavedAmount(savedAmount, userId: userId)
            }
        }
    }
    
    // MARK: - Chat 回来的入口
    // 处理决策状态变化
    private func applyDecisionChange(_ updated: Decision, newStatus: Decision.Status) {
        guard let userId = authService.currentUserId else { return }
        
        if let idx = decisions.firstIndex(where: { $0.id == updated.id }) {
            let oldDecision = decisions[idx]
            var newDecision = updated
            newDecision.status = newStatus
            decisions[idx] = newDecision
            reconcile(old: oldDecision, new: newDecision, userId: userId)
        } else {
            var newDecision = updated
            newDecision.status = newStatus
            decisions.insert(newDecision, at: 0)
            reconcile(old: nil, new: newDecision, userId: userId)
        }
    }
    
    // MARK: - 差量更新
    // 处理决策状态变化
    private func reconcile(old: Decision?, new: Decision, userId: String) {
        let price = new.price
        
        // 保存决策到Firebase
        Task {
            try? await dataManager.saveDecision(new, userId: userId)
        }
        
        switch (old?.status, new.status) {
        // 新的 / pending -> 买了
        case (.none, .purchased),
             (.some(.pending), .purchased):
            addExpense(for: new, userId: userId)
            
        // 新的 / pending -> 不买
        case (.none, .skipped),
             (.some(.pending), .skipped):
            savedAmount += price
            Task {
                try? await dataManager.saveSavedAmount(savedAmount, userId: userId)
            }
            
        // 买了 -> 不买
        case (.some(.purchased), .skipped):
            removeExpense(matching: new, userId: userId)
            savedAmount += price
            Task {
                try? await dataManager.saveSavedAmount(savedAmount, userId: userId)
            }
            
        // 不买 -> 买了
        case (.some(.skipped), .purchased):
            if savedAmount >= price {
                savedAmount -= price
            } else {
                savedAmount = 0
            }
            Task {
                try? await dataManager.saveSavedAmount(savedAmount, userId: userId)
            }
            addExpense(for: new, userId: userId)
            
        default:
            break
        }
    }
    
    // MARK: - 加消费
    // 添加消费记录
    private func addExpense(for decision: Decision, userId: String) {
        let item = ExpenseItem(
            id: UUID(),
            decisionId: decision.id,
            name: decision.title,
            price: decision.price,
            date: .now
        )
        expenses.insert(item, at: 0)
        
        // 保存到Firebase
        Task {
            try? await dataManager.saveExpense(item, userId: userId)
        }
    }
    
    // MARK: - 删消费
    // 删除消费记录
    private func removeExpense(matching decision: Decision, userId: String) {
        if let idx = expenses.firstIndex(where: { $0.decisionId == decision.id }) {
            let expense = expenses[idx]
            expenses.remove(at: idx)
            // 从Firebase删除
            Task {
                try? await dataManager.deleteExpense(expense, userId: userId)
            }
        } else if let idx = expenses.firstIndex(where: { $0.name == decision.title && $0.price == decision.price }) {
            let expense = expenses[idx]
            expenses.remove(at: idx)
            // 从Firebase删除
            Task {
                try? await dataManager.deleteExpense(expense, userId: userId)
            }
        }
    }
}
