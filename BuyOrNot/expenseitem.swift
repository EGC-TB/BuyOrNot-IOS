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
    var name: String
    var price: Double
    var date: Date
}
