//
//  DecisionFormViewWrapper.swift
//  BuyOrNot
//  Neo - 11/8
//

import SwiftUI
import UIKit

// 包装器，用于传递图片
struct DecisionFormViewWrapper: View {
    var onCreate: (Decision, UIImage?) -> Void
    
    var body: some View {
        DecisionFormView { decision, image in
            onCreate(decision, image)
        }
    }
}

