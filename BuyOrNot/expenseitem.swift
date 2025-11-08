//
//  expenseitem.swift
//  BuyOrNot
//
//  Created by Eagle Chen on 11/7/25.
//

// ExpenseItem.swift
import Foundation

struct ExpenseItem: Identifiable, Hashable {
    var id: UUID
    var decisionId: UUID?   // 👈 用来反向找到这条消费是谁生成的
    var name: String
    var price: Double
    var date: Date
}
