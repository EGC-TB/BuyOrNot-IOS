//
//  ConversationEmbedding.swift
//  BuyOrNot
//
//  Created for RAG Implementation
//

import Foundation

// 对话嵌入模型
struct ConversationEmbedding: Codable, Identifiable {
    let id: UUID
    let decisionId: UUID
    let userId: String
    let embedding: [Float]
    let text: String
    let summary: String
    let timestamp: Date
    
    init(id: UUID = UUID(), decisionId: UUID, userId: String, embedding: [Float], text: String, summary: String, timestamp: Date = Date()) {
        self.id = id
        self.decisionId = decisionId
        self.userId = userId
        self.embedding = embedding
        self.text = text
        self.summary = summary
        self.timestamp = timestamp
    }
}

