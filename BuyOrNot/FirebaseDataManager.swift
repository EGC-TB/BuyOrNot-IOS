//
//  FirebaseDataManager.swift
//  BuyOrNot
//  Neo - 11/8
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class FirebaseDataManager: ObservableObject {
    private let db = Firestore.firestore()
    private var listenerRegistrations: [ListenerRegistration] = []
    
    // 决策的list (collection)
    private func decisionsCollection(userId: String) -> CollectionReference {
        return db.collection("users").document(userId).collection("decisions")
    }
    
    // 花费的list (collection)
    private func expensesCollection(userId: String) -> CollectionReference {
        return db.collection("users").document(userId).collection("expenses")
    }
    
    // 用户的信息 (collection)
    private func userProfileDocument(userId: String) -> DocumentReference {
        return db.collection("users").document(userId)
    }
    
    // MARK: - Decisions
    
    // 加一个新的决策
    func saveDecision(_ decision: Decision, userId: String) async throws {
        let decisionData: [String: Any] = [
            "id": decision.id.uuidString,
            "title": decision.title,
            "price": decision.price,
            "date": Timestamp(date: decision.date),
            "status": decision.status.rawValue
        ]
        
        // 加入collection
        try await decisionsCollection(userId: userId)
            .document(decision.id.uuidString)
            .setData(decisionData)
    }
    
    // 删除决策
    func deleteDecision(_ decision: Decision, userId: String) async throws {
        try await decisionsCollection(userId: userId)
            .document(decision.id.uuidString)
            .delete()
    }
    
    // 决策之后加载 (listener)
    func listenToDecisions(userId: String, onUpdate: @escaping ([Decision]) -> Void) {
        let listener = decisionsCollection(userId: userId)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    if let error = error {
                        print("Error fetching decisions: \(error)")
                    }
                    onUpdate([])
                    return
                }
                
                let decisions = documents.compactMap { doc -> Decision? in
                    let data = doc.data()
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let title = data["title"] as? String,
                          let price = data["price"] as? Double,
                          let timestamp = data["date"] as? Timestamp,
                          let statusString = data["status"] as? String,
                          let status = Decision.Status(rawValue: statusString) else {
                        return nil
                    }
                    
                    return Decision(
                        id: id,
                        title: title,
                        price: price,
                        date: timestamp.dateValue(),
                        status: status
                    )
                }
                
                onUpdate(decisions)
            }
        
        listenerRegistrations.append(listener)
    }
    
    // MARK: - Expenses
    
    // 加入花销
    func saveExpense(_ expense: ExpenseItem, userId: String) async throws {
        var expenseData: [String: Any] = [
            "id": expense.id.uuidString,
            "name": expense.name,
            "price": expense.price,
            "date": Timestamp(date: expense.date)
        ]
        
        if let decisionId = expense.decisionId {
            expenseData["decisionId"] = decisionId.uuidString
        }
        
        // 扔进去
        try await expensesCollection(userId: userId)
            .document(expense.id.uuidString)
            .setData(expenseData)
    }
    
    // 删除花销
    func deleteExpense(_ expense: ExpenseItem, userId: String) async throws {
        try await expensesCollection(userId: userId)
            .document(expense.id.uuidString)
            .delete()
    }
    
    // 花销之后加载 (listener)
    func listenToExpenses(userId: String, onUpdate: @escaping ([ExpenseItem]) -> Void) {
        let listener = expensesCollection(userId: userId)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    if let error = error {
                        print("Error fetching expenses: \(error)")
                    }
                    onUpdate([])
                    return
                }
                
                let expenses = documents.compactMap { doc -> ExpenseItem? in
                    let data = doc.data()
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let name = data["name"] as? String,
                          let price = data["price"] as? Double,
                          let timestamp = data["date"] as? Timestamp else {
                        return nil
                    }
                    
                    var decisionId: UUID? = nil
                    if let decisionIdString = data["decisionId"] as? String {
                        decisionId = UUID(uuidString: decisionIdString)
                    }
                    
                    return ExpenseItem(
                        id: id,
                        decisionId: decisionId,
                        name: name,
                        price: price,
                        date: timestamp.dateValue()
                    )
                }
                
                onUpdate(expenses)
            }
        
        listenerRegistrations.append(listener)
    }
    
    // MARK: - User Profile
    
    // 用户的信息
    func saveUserProfile(name: String, email: String, userId: String) async throws {
        let profileData: [String: Any] = [
            "name": name,
            "email": email,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await userProfileDocument(userId: userId)
            .setData(profileData, merge: true)
    }
    
    // 加载用户信息
    func loadUserProfile(userId: String) async throws -> (name: String, email: String)? {
        let document = try await userProfileDocument(userId: userId).getDocument()
        
        guard let data = document.data(),
              let name = data["name"] as? String,
              let email = data["email"] as? String else {
            return nil
        }
        
        return (name: name, email: email)
    }
    
    // 写新的省了多少
    func saveSavedAmount(_ amount: Double, userId: String) async throws {
        try await userProfileDocument(userId: userId)
            .setData(["savedAmount": amount], merge: true)
    }
    
    // 加载省了多少
    func loadSavedAmount(userId: String) async throws -> Double {
        let document = try await userProfileDocument(userId: userId).getDocument()
        return document.data()?["savedAmount"] as? Double ?? 0.0
    }
    
    // MARK: - Cleanup
    // 移除所有listener
    func removeAllListeners() {
        listenerRegistrations.forEach { $0.remove() }
        listenerRegistrations.removeAll()
    }
}
