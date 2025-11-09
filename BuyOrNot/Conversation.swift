//
//  Conversation.swift
//  BuyOrNot
//
//  Created for Conversation Storage
//

import Foundation
import UIKit

// 可编码的消息（用于Firestore存储）
struct CodableChatMessage: Codable {
    let id: String
    let role: String // "user" or "assistant"
    let text: String
    let imageData: String? // Base64 encoded image
    let time: Date
    
    init(id: String, role: String, text: String, imageData: String?, time: Date) {
        self.id = id
        self.role = role
        self.text = text
        self.imageData = imageData
        self.time = time
    }
    
    init(from message: ChatMessage) {
        self.id = message.id.uuidString
        self.role = message.role == .user ? "user" : "assistant"
        self.text = message.text
        
        // 压缩并编码图片（如果存在）
        if let image = message.image {
            // 压缩图片以减少存储大小
            let maxDimension: CGFloat = 1024
            let resizedImage = CodableChatMessage.resizeImage(image, maxDimension: maxDimension)
            if let jpegData = resizedImage.jpegData(compressionQuality: 0.8) {
                self.imageData = jpegData.base64EncodedString()
                print("📸 Encoded image for message: \(self.id) (original: \(image.size), resized: \(resizedImage.size), data size: \(jpegData.count) bytes)")
            } else {
                print("⚠️ Failed to convert image to JPEG data for message: \(self.id)")
                self.imageData = nil
            }
        } else {
            self.imageData = nil
        }
        
        self.time = message.time
    }
    
    // 辅助函数：调整图片大小（静态方法）
    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // 如果图片已经足够小，直接返回
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // 计算缩放比例
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        // 调整图片大小
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    func toChatMessage() -> ChatMessage? {
        guard let uuid = UUID(uuidString: id) else {
            print("⚠️ Failed to parse message ID: \(id)")
            return nil
        }
        
        // 确定角色
        let roleEnum: ChatMessage.Role = role == "user" ? .user : .assistant
        
        var message = ChatMessage(id: uuid, role: roleEnum, text: text, time: time)
        
        // 解码图片
        if let imageDataString = imageData {
            if let imageData = Data(base64Encoded: imageDataString) {
                if let image = UIImage(data: imageData) {
                    message.image = image
                    print("✅ Successfully decoded image for message: \(id) (size: \(imageData.count) bytes)")
                } else {
                    print("⚠️ Failed to create UIImage from data for message: \(id)")
                }
            } else {
                print("⚠️ Failed to decode base64 image data for message: \(id)")
            }
        }
        
        return message
    }
}

// 完整对话模型
struct Conversation: Codable, Identifiable {
    let id: UUID
    let decisionId: UUID
    let userId: String
    let messages: [CodableChatMessage]
    let lastUpdated: Date
    let isActive: Bool // 是否还在进行中
    
    // 从ChatMessage数组初始化（用于保存）
    init(id: UUID = UUID(), decisionId: UUID, userId: String, messages: [ChatMessage], lastUpdated: Date = Date(), isActive: Bool = true) {
        self.id = id
        self.decisionId = decisionId
        self.userId = userId
        self.messages = messages.map { CodableChatMessage(from: $0) }
        self.lastUpdated = lastUpdated
        self.isActive = isActive
    }
    
    // 从CodableChatMessage数组初始化（用于加载）
    init(id: UUID, decisionId: UUID, userId: String, codableMessages: [CodableChatMessage], lastUpdated: Date, isActive: Bool) {
        self.id = id
        self.decisionId = decisionId
        self.userId = userId
        self.messages = codableMessages
        self.lastUpdated = lastUpdated
        self.isActive = isActive
    }
    
    // 转换为ChatMessage数组
    func toChatMessages() -> [ChatMessage] {
        return messages.compactMap { $0.toChatMessage() }
    }
}

