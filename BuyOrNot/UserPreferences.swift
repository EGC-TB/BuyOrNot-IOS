//
//  UserPreferences.swift
//  BuyOrNot
//
//  Created for RAG Implementation
//

import Foundation

// 用户偏好模型
struct UserPreferences: Codable {
    let userId: String
    var preferredCategories: [String]
    var averagePriceRange: PriceRange
    var decisionPatterns: DecisionPatterns
    var lastUpdated: Date
    
    init(userId: String, preferredCategories: [String] = [], averagePriceRange: PriceRange = PriceRange(min: 0, max: 0), decisionPatterns: DecisionPatterns = DecisionPatterns(), lastUpdated: Date = Date()) {
        self.userId = userId
        self.preferredCategories = preferredCategories
        self.averagePriceRange = averagePriceRange
        self.decisionPatterns = decisionPatterns
        self.lastUpdated = lastUpdated
    }
}

// 价格范围
struct PriceRange: Codable {
    let min: Double
    let max: Double
}

// 决策模式
struct DecisionPatterns: Codable {
    var totalDecisions: Int
    var boughtCount: Int
    var skippedCount: Int
    var averagePriceBought: Double
    var averagePriceSkipped: Double
    var buyRatio: Double {
        guard totalDecisions > 0 else { return 0 }
        return Double(boughtCount) / Double(totalDecisions)
    }
    
    init(totalDecisions: Int = 0, boughtCount: Int = 0, skippedCount: Int = 0, averagePriceBought: Double = 0, averagePriceSkipped: Double = 0) {
        self.totalDecisions = totalDecisions
        self.boughtCount = boughtCount
        self.skippedCount = skippedCount
        self.averagePriceBought = averagePriceBought
        self.averagePriceSkipped = averagePriceSkipped
    }
}

