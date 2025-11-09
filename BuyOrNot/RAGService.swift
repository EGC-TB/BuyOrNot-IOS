//
//  RAGService.swift
//  BuyOrNot
//
//  Created for RAG Implementation
//

import Foundation

// RAG上下文
struct RAGContext {
    let relevantConversations: [ConversationEmbedding]
    let userPreferences: UserPreferences?
    let decisionPatterns: DecisionPatterns?
    
    // 构建增强提示的文本
    func buildContextPrompt() -> String {
        var prompt = ""
        
        // 添加用户偏好
        if let preferences = userPreferences {
            prompt += "User Preferences:\n"
            if preferences.averagePriceRange.max > 0 {
                prompt += "- Average price range: $\(String(format: "%.2f", preferences.averagePriceRange.min)) - $\(String(format: "%.2f", preferences.averagePriceRange.max))\n"
            }
            if !preferences.preferredCategories.isEmpty {
                prompt += "- Preferred categories: \(preferences.preferredCategories.joined(separator: ", "))\n"
            }
            prompt += "- Buy ratio: \(String(format: "%.1f", preferences.decisionPatterns.buyRatio * 100))%\n"
            prompt += "- Total decisions: \(preferences.decisionPatterns.totalDecisions)\n"
            prompt += "\n"
        }
        
        // 添加相关对话
        if !relevantConversations.isEmpty {
            prompt += "Past Similar Decisions:\n"
            for (index, conversation) in relevantConversations.enumerated() {
                prompt += "\(index + 1). \(conversation.summary)\n"
                if index < 2 { // 只显示前2个的详细内容
                    prompt += "   Details: \(conversation.text.prefix(200))...)\n"
                }
            }
            prompt += "\n"
        }
        
        return prompt
    }
}

// RAG服务
class RAGService {
    private let embeddingService: EmbeddingService
    private let vectorSearchService: VectorSearchService
    private let dataManager: FirebaseDataManager
    
    init(embeddingService: EmbeddingService, vectorSearchService: VectorSearchService, dataManager: FirebaseDataManager) {
        self.embeddingService = embeddingService
        self.vectorSearchService = vectorSearchService
        self.dataManager = dataManager
    }
    
    // 检索相关上下文
    @MainActor
    func retrieveContext(
        for decision: Decision,
        currentMessages: [ChatMessage],
        userId: String
    ) async throws -> RAGContext {
        // 1. 生成当前对话的嵌入
        let currentEmbedding = try await embeddingService.generateDecisionEmbedding(
            decision: decision,
            messages: currentMessages
        )
        
        // 2. 搜索相似对话
        let similarConversations = try await vectorSearchService.findSimilarConversations(
            embedding: currentEmbedding,
            userId: userId,
            excludingDecisionId: decision.id,
            limit: 5,
            minSimilarity: 0.5
        )
        
        // 3. 加载用户偏好
        let userPreferences = try? await dataManager.loadUserPreferences(userId: userId)
        
        return RAGContext(
            relevantConversations: similarConversations,
            userPreferences: userPreferences,
            decisionPatterns: userPreferences?.decisionPatterns
        )
    }
    
    // 存储对话和嵌入
    @MainActor
    func storeConversation(
        decisionId: UUID,
        messages: [ChatMessage],
        decision: Decision,
        userId: String
    ) async throws {
        // 1. 生成嵌入
        let embedding = try await embeddingService.generateDecisionEmbedding(
            decision: decision,
            messages: messages
        )
        
        // 2. 生成对话摘要
        let summary = generateSummary(decision: decision, messages: messages)
        
        // 3. 生成对话文本
        let conversationText = messages.map { message in
            let roleString = message.role == .user ? "User" : "Assistant"
            return "\(roleString): \(message.text)"
        }.joined(separator: "\n")
        
        // 4. 创建嵌入对象
        let conversationEmbedding = ConversationEmbedding(
            decisionId: decisionId,
            userId: userId,
            embedding: embedding,
            text: conversationText,
            summary: summary
        )
        
        // 5. 保存到Firestore
        try await dataManager.saveConversationEmbedding(conversationEmbedding, userId: userId)
        
        // 6. 更新用户偏好（异步，不阻塞）
        Task {
            await updateUserPreferences(decision: decision, userId: userId)
        }
    }
    
    // 生成对话摘要
    private func generateSummary(decision: Decision, messages: [ChatMessage]) -> String {
        // 简单摘要：产品名称和最终决定
        let productInfo = "\(decision.title) ($\(String(format: "%.2f", decision.price)))"
        
        // 查找是否有明确的决定
        let lastMessages = messages.suffix(3)
        for message in lastMessages.reversed() {
            let text = message.text.lowercased()
            if text.contains("buy") || text.contains("purchase") {
                return "Decided to buy \(productInfo)"
            } else if text.contains("skip") || text.contains("not buy") || text.contains("don't buy") {
                return "Decided to skip \(productInfo)"
            }
        }
        
        return "Discussed \(productInfo)"
    }
    
    // 更新用户偏好
    @MainActor
    private func updateUserPreferences(decision: Decision, userId: String) async {
        do {
            // 加载现有偏好
            var preferences = try await dataManager.loadUserPreferences(userId: userId)
            
            // 如果不存在，创建新的
            if preferences == nil {
                preferences = UserPreferences(userId: userId)
            }
            
            guard let existingPrefs = preferences else { return }
            
            // 创建新的决策模式
            let newTotalDecisions = existingPrefs.decisionPatterns.totalDecisions + 1
            var newBoughtCount = existingPrefs.decisionPatterns.boughtCount
            var newSkippedCount = existingPrefs.decisionPatterns.skippedCount
            var newAvgPriceBought = existingPrefs.decisionPatterns.averagePriceBought
            var newAvgPriceSkipped = existingPrefs.decisionPatterns.averagePriceSkipped
            
            if decision.status == .purchased {
                newBoughtCount += 1
                // 更新平均价格
                let totalBought = newBoughtCount
                let currentAvg = existingPrefs.decisionPatterns.averagePriceBought
                newAvgPriceBought = 
                    (currentAvg * Double(totalBought - 1) + decision.price) / Double(totalBought)
            } else if decision.status == .skipped {
                newSkippedCount += 1
                // 更新平均价格
                let totalSkipped = newSkippedCount
                let currentAvg = existingPrefs.decisionPatterns.averagePriceSkipped
                newAvgPriceSkipped = 
                    (currentAvg * Double(totalSkipped - 1) + decision.price) / Double(totalSkipped)
            }
            
            let newDecisionPatterns = DecisionPatterns(
                totalDecisions: newTotalDecisions,
                boughtCount: newBoughtCount,
                skippedCount: newSkippedCount,
                averagePriceBought: newAvgPriceBought,
                averagePriceSkipped: newAvgPriceSkipped
            )
            
            // 更新价格范围
            let newPriceRange: PriceRange
            if existingPrefs.averagePriceRange.max == 0 {
                newPriceRange = PriceRange(min: decision.price, max: decision.price)
            } else {
                let newMin = min(existingPrefs.averagePriceRange.min, decision.price)
                let newMax = max(existingPrefs.averagePriceRange.max, decision.price)
                newPriceRange = PriceRange(min: newMin, max: newMax)
            }
            
            let updatedPreferences = UserPreferences(
                userId: userId,
                preferredCategories: existingPrefs.preferredCategories,
                averagePriceRange: newPriceRange,
                decisionPatterns: newDecisionPatterns,
                lastUpdated: Date()
            )
            
            // 保存更新后的偏好
            try await dataManager.saveUserPreferences(updatedPreferences, userId: userId)
        } catch {
            print("Error updating user preferences: \(error)")
        }
    }
}

