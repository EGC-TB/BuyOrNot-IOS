//
//  decision.swift
//  BuyOrNot
//
//  Created by Eagle Chen on 11/7/25.
//
import Foundation

struct Decision: Identifiable, Hashable, Codable {
    enum Status: String, Codable {
        case pending
        case skipped
        case purchased
    }
    
    var id: UUID
    var title: String
    var price: Double
    var date: Date
    var status: Status
}
