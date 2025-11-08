//
//  chatmessage.swift
//  BuyOrNot
//
//  Created by Eagle Chen on 11/7/25.
//

import Foundation
import UIKit

struct ChatMessage: Identifiable, Hashable {
    enum Role {
        case user
        case assistant
    }
    
    var id = UUID()
    var role: Role
    var text: String
    var image: UIImage? = nil
    var time: Date = .now
    
    // Hashable conformance - ignore image in hash
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(role)
        hasher.combine(text)
        hasher.combine(time)
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id && lhs.role == rhs.role && lhs.text == rhs.text && lhs.time == rhs.time
    }
}
