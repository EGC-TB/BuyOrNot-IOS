//
//  EmbeddingService.swift
//  BuyOrNot
//
//  Created for RAG Implementation
//

import Foundation

// 嵌入服务错误
enum EmbeddingError: LocalizedError {
    case invalidAPIKey
    case networkError
    case parseError
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key"
        case .networkError:
            return "Network error, please try again"
        case .parseError:
            return "Failed to parse embedding response"
        case .apiError(let message):
            return message
        }
    }
}

// 嵌入生成服务
class EmbeddingService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // 为文本生成嵌入
    func generateEmbedding(for text: String) async throws -> [Float] {
        guard !text.isEmpty else {
            throw EmbeddingError.apiError("Text cannot be empty")
        }
        
        let url = URL(string: "\(baseURL)/models/text-embedding-004:embedContent?key=\(apiKey)")!
        
        let payload: [String: Any] = [
            "model": "models/text-embedding-004",
            "content": [
                "parts": [
                    ["text": text]
                ]
            ]
        ]
        
        let body = try JSONSerialization.data(withJSONObject: payload)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmbeddingError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw EmbeddingError.apiError(message)
            }
            throw EmbeddingError.apiError("Server returned status code \(httpResponse.statusCode)")
        }
        
        // 解析响应
        guard let result = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let embedding = result["embedding"] as? [String: Any],
              let values = embedding["values"] as? [Double] else {
            throw EmbeddingError.parseError
        }
        
        // 转换为Float数组
        return values.map { Float($0) }
    }
    
    // 为对话生成嵌入
    func generateConversationEmbedding(messages: [ChatMessage]) async throws -> [Float] {
        // 合并消息为单个文本
        let conversationText = messages.map { message in
            let roleString = message.role == .user ? "User" : "Assistant"
            return "\(roleString): \(message.text)"
        }.joined(separator: "\n")
        
        return try await generateEmbedding(for: conversationText)
    }
    
    // 为决策生成嵌入（用于搜索相似决策）
    func generateDecisionEmbedding(decision: Decision, messages: [ChatMessage]) async throws -> [Float] {
        // 组合决策信息和对话
        let decisionText = "Product: \(decision.title), Price: $\(String(format: "%.2f", decision.price))"
        let conversationText = messages.map { message in
            let roleString = message.role == .user ? "User" : "Assistant"
            return "\(roleString): \(message.text)"
        }.joined(separator: "\n")
        
        let combinedText = "\(decisionText)\n\nConversation:\n\(conversationText)"
        return try await generateEmbedding(for: combinedText)
    }
}

