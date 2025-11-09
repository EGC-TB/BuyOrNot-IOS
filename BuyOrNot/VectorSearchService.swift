//
//  VectorSearchService.swift
//  BuyOrNot
//
//  Created for RAG Implementation
//

import Foundation
import FirebaseFirestore

// 向量搜索服务
@MainActor
class VectorSearchService {
    private let dataManager: FirebaseDataManager
    
    init(dataManager: FirebaseDataManager) {
        self.dataManager = dataManager
    }
    
    // 计算余弦相似度
    func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        
        // 计算点积
        let dotProduct = zip(a, b).map { $0 * $1 }.reduce(0, +)
        
        // 计算向量大小
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        guard magnitudeA > 0 && magnitudeB > 0 else { return 0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    // 查找相似对话
    func findSimilarConversations(
        embedding: [Float],
        userId: String,
        limit: Int = 5,
        minSimilarity: Float = 0.5
    ) async throws -> [ConversationEmbedding] {
        // 加载所有对话嵌入
        let allEmbeddings = try await dataManager.loadConversationEmbeddings(userId: userId, limit: 100)
        
        // 计算相似度并排序
        let similarities = allEmbeddings.map { conversationEmbedding in
            let similarity = cosineSimilarity(embedding, conversationEmbedding.embedding)
            return (conversationEmbedding, similarity)
        }
        .filter { $0.1 >= minSimilarity } // 过滤低相似度
        .sorted { $0.1 > $1.1 } // 按相似度降序排序
        .prefix(limit) // 取前N个
        
        return similarities.map { $0.0 }
    }
    
    // 查找相似对话（排除当前决策）
    func findSimilarConversations(
        embedding: [Float],
        userId: String,
        excludingDecisionId: UUID,
        limit: Int = 5,
        minSimilarity: Float = 0.3
    ) async throws -> [ConversationEmbedding] {
        let allResults = try await findSimilarConversations(
            embedding: embedding,
            userId: userId,
            limit: limit * 2, // 获取更多结果以便过滤
            minSimilarity: minSimilarity
        )
        
        // 排除当前决策
        let filtered = allResults.filter { $0.decisionId != excludingDecisionId }
        
        return Array(filtered.prefix(limit))
    }
}

