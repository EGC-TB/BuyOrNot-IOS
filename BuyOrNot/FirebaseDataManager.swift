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
    
    // MARK: - Conversations (Full Storage)
    
    // 完整对话的collection
    private func conversationsCollection(userId: String) -> CollectionReference {
        return db.collection("users").document(userId).collection("conversations")
    }
    
    // 保存或更新对话
    func saveConversation(_ conversation: Conversation, userId: String) async throws {
        // 构建消息数组，确保正确处理 nil 值
        var messagesArray: [[String: Any]] = []
        for msg in conversation.messages {
            var messageDict: [String: Any] = [
                "id": msg.id,
                "role": msg.role,
                "text": msg.text,
                "time": Timestamp(date: msg.time)
            ]
            
            // 只有当 imageData 不为 nil 时才添加
            if let imageData = msg.imageData {
                messageDict["imageData"] = imageData
            }
            
            messagesArray.append(messageDict)
        }
        
        let conversationData: [String: Any] = [
            "id": conversation.id.uuidString,
            "decisionId": conversation.decisionId.uuidString,
            "userId": conversation.userId,
            "messages": messagesArray,
            "lastUpdated": Timestamp(date: conversation.lastUpdated),
            "isActive": conversation.isActive
        ]
        
        print("💾 Saving conversation: \(conversation.id.uuidString) with \(conversation.messages.count) messages")
        print("📸 Messages with images: \(conversation.messages.filter { $0.imageData != nil }.count)")
        
        // 使用 setData 而不是 merge，因为数组需要完全替换
        try await conversationsCollection(userId: userId)
            .document(conversation.id.uuidString)
            .setData(conversationData, merge: false)
        
        print("✅ Successfully saved conversation: \(conversation.id.uuidString)")
    }
    
    // 加载对话（根据决策ID）
    func loadConversation(decisionId: UUID, userId: String) async throws -> Conversation? {
        let query = conversationsCollection(userId: userId)
            .whereField("decisionId", isEqualTo: decisionId.uuidString)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        guard let doc = snapshot.documents.first else {
            print("ℹ️ No conversation document found for decisionId: \(decisionId.uuidString)")
            return nil
        }
        
        let data = doc.data()
        print("📝 Found conversation document: \(doc.documentID)")
        
        guard let conversation = try parseConversation(from: data) else {
            print("⚠️ Failed to parse conversation from document data")
            return nil
        }
        
        return conversation
    }
    
    // 加载所有对话
    func loadAllConversations(userId: String) async throws -> [Conversation] {
        let snapshot = try await conversationsCollection(userId: userId)
            .order(by: "lastUpdated", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            try? parseConversation(from: doc.data())
        }
    }
    
    // 解析对话数据
    private func parseConversation(from data: [String: Any]) throws -> Conversation? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let decisionIdString = data["decisionId"] as? String,
              let decisionId = UUID(uuidString: decisionIdString),
              let userId = data["userId"] as? String,
              let messagesData = data["messages"] as? [[String: Any]],
              let lastUpdatedTimestamp = data["lastUpdated"] as? Timestamp,
              let isActive = data["isActive"] as? Bool else {
            return nil
        }
        
        let messages = messagesData.compactMap { msgData -> CodableChatMessage? in
            guard let id = msgData["id"] as? String,
                  let role = msgData["role"] as? String,
                  let text = msgData["text"] as? String,
                  let timeTimestamp = msgData["time"] as? Timestamp else {
                print("⚠️ Failed to parse message: missing required fields")
                return nil
            }
            
            // imageData 可以为 nil（如果消息中没有图片，这个字段可能不存在）
            let imageData = msgData["imageData"] as? String
            
            if imageData != nil {
                print("📸 Found image data for message: \(id)")
            }
            
            return CodableChatMessage(
                id: id,
                role: role,
                text: text,
                imageData: imageData,
                time: timeTimestamp.dateValue()
            )
        }
        
        let messagesWithImages = messages.filter { $0.imageData != nil }.count
        print("📝 Parsed \(messages.count) messages from Firestore (\(messagesWithImages) with images)")
        
        return Conversation(
            id: id,
            decisionId: decisionId,
            userId: userId,
            codableMessages: messages,
            lastUpdated: lastUpdatedTimestamp.dateValue(),
            isActive: isActive
        )
    }
    
    // MARK: - Conversation Embeddings (RAG)
    
    // 对话嵌入的collection
    private func conversationEmbeddingsCollection(userId: String) -> CollectionReference {
        return db.collection("users").document(userId).collection("conversationEmbeddings")
    }
    
    // 保存对话嵌入
    func saveConversationEmbedding(_ embedding: ConversationEmbedding, userId: String) async throws {
        let embeddingData: [String: Any] = [
            "id": embedding.id.uuidString,
            "decisionId": embedding.decisionId.uuidString,
            "userId": embedding.userId,
            "embedding": embedding.embedding.map { Double($0) }, // Firestore doesn't support Float arrays
            "text": embedding.text,
            "summary": embedding.summary,
            "timestamp": Timestamp(date: embedding.timestamp)
        ]
        
        try await conversationEmbeddingsCollection(userId: userId)
            .document(embedding.id.uuidString)
            .setData(embeddingData)
    }
    
    // 加载所有对话嵌入（用于向量搜索）
    func loadConversationEmbeddings(userId: String, limit: Int = 100) async throws -> [ConversationEmbedding] {
        let query = conversationEmbeddingsCollection(userId: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
        
        let snapshot = try await query.getDocuments()
        
        return snapshot.documents.compactMap { doc -> ConversationEmbedding? in
            let data = doc.data()
            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let decisionIdString = data["decisionId"] as? String,
                  let decisionId = UUID(uuidString: decisionIdString),
                  let userId = data["userId"] as? String,
                  let embeddingDoubles = data["embedding"] as? [Double],
                  let text = data["text"] as? String,
                  let summary = data["summary"] as? String,
                  let timestamp = data["timestamp"] as? Timestamp else {
                return nil
            }
            
            let embedding = embeddingDoubles.map { Float($0) }
            
            return ConversationEmbedding(
                id: id,
                decisionId: decisionId,
                userId: userId,
                embedding: embedding,
                text: text,
                summary: summary,
                timestamp: timestamp.dateValue()
            )
        }
    }
    
    // MARK: - User Preferences (RAG)
    
    // 用户偏好的document
    private func userPreferencesDocument(userId: String) -> DocumentReference {
        return db.collection("users").document(userId).collection("preferences").document("userPreferences")
    }
    
    // 保存用户偏好
    func saveUserPreferences(_ preferences: UserPreferences, userId: String) async throws {
        let preferencesData: [String: Any] = [
            "userId": preferences.userId,
            "preferredCategories": preferences.preferredCategories,
            "averagePriceRange": [
                "min": preferences.averagePriceRange.min,
                "max": preferences.averagePriceRange.max
            ],
            "decisionPatterns": [
                "totalDecisions": preferences.decisionPatterns.totalDecisions,
                "boughtCount": preferences.decisionPatterns.boughtCount,
                "skippedCount": preferences.decisionPatterns.skippedCount,
                "averagePriceBought": preferences.decisionPatterns.averagePriceBought,
                "averagePriceSkipped": preferences.decisionPatterns.averagePriceSkipped
            ],
            "lastUpdated": Timestamp(date: preferences.lastUpdated)
        ]
        
        try await userPreferencesDocument(userId: userId)
            .setData(preferencesData, merge: true)
    }
    
    // 加载用户偏好
    func loadUserPreferences(userId: String) async throws -> UserPreferences? {
        let document = try await userPreferencesDocument(userId: userId).getDocument()
        
        guard let data = document.data(),
              let userId = data["userId"] as? String,
              let preferredCategories = data["preferredCategories"] as? [String],
              let priceRangeData = data["averagePriceRange"] as? [String: Double],
              let min = priceRangeData["min"],
              let max = priceRangeData["max"],
              let patternsData = data["decisionPatterns"] as? [String: Any],
              let totalDecisions = patternsData["totalDecisions"] as? Int,
              let boughtCount = patternsData["boughtCount"] as? Int,
              let skippedCount = patternsData["skippedCount"] as? Int,
              let averagePriceBought = patternsData["averagePriceBought"] as? Double,
              let averagePriceSkipped = patternsData["averagePriceSkipped"] as? Double,
              let lastUpdatedTimestamp = data["lastUpdated"] as? Timestamp else {
            return nil
        }
        
        let priceRange = PriceRange(min: min, max: max)
        let decisionPatterns = DecisionPatterns(
            totalDecisions: totalDecisions,
            boughtCount: boughtCount,
            skippedCount: skippedCount,
            averagePriceBought: averagePriceBought,
            averagePriceSkipped: averagePriceSkipped
        )
        
        return UserPreferences(
            userId: userId,
            preferredCategories: preferredCategories,
            averagePriceRange: priceRange,
            decisionPatterns: decisionPatterns,
            lastUpdated: lastUpdatedTimestamp.dateValue()
        )
    }
    
    // MARK: - Cleanup
    // 移除所有listener
    func removeAllListeners() {
        listenerRegistrations.forEach { $0.remove() }
        listenerRegistrations.removeAll()
    }
}
