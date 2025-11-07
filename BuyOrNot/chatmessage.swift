//
//  chatmessage.swift
//  BuyOrNot
//
//  Created by Eagle Chen on 11/7/25.
//

import Foundation

struct ChatMessage: Identifiable, Hashable {
    enum Role {
        case user
        case assistant
    }
    
    var id = UUID()
    var role: Role
    var text: String
    var time: Date = .now
}
