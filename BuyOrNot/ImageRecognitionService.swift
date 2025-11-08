//
//  ImageRecognitionService.swift
//  BuyOrNot
//  Neo - 11/8
//

import Foundation
import UIKit

// 识别结果
struct RecognitionResult {
    let productName: String
    let price: Double?
}

// 图片识别服务
class ImageRecognitionService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // 识别产品
    func recognizeProduct(from image: UIImage) async throws -> RecognitionResult {
        // 处理图片：调整大小和压缩
        let processedImage = resizeImage(image, maxDimension: 1024)
        
        // 编码图片为base64
        guard let base64Image = encodeImage(processedImage) else {
            throw RecognitionError.invalidImage
        }
        
        // 构建API请求 - 使用gemini-2.5-pro模型
        let url = URL(string: "\(baseURL)/models/gemini-2.5-pro:generateContent?key=\(apiKey)")!
        
        let prompt = """
        You are analyzing a product image. Extract the following information:
        
        1. Product name: Identify what product/item is shown in the image. Keep the name SHORT and CONCISE (2-4 words maximum). Use the brand name and product type only (e.g., "iPhone 15", "MacBook Pro", "Nike Shoes", "Coffee Maker"). Do not include detailed descriptions, model numbers, or specifications unless essential.
        2. Price: If there is any price tag, label, sticker, or visible price text anywhere in the image, extract the numeric value (remove currency symbols, commas, etc.). Only extract if you are confident about the price.
        
        IMPORTANT: Return ONLY a valid JSON object in this exact format, with no additional text before or after:
        {"productName": "short product name or 'Failed to identify product'", "price": number or null}
        
        Rules:
        - Product name must be SHORT and CONCISE (2-4 words max)
        - If you cannot clearly identify what product is shown, set productName to "Failed to identify product"
        - If no price is visible or you're uncertain, set price to null (not 0)
        - The price should be a number, not a string
        - Do not include markdown formatting, code blocks, or any text outside the JSON
        """
        
        let payload: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    [
                        "inlineData": [
                            "mimeType": "image/jpeg",
                            "data": base64Image
                        ]
                    ]
                ]
            ]]
        ]
        
        let body = try JSONSerialization.data(withJSONObject: payload)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RecognitionError.networkError
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? [String: Any],
               let message = errorMessage["message"] as? String {
                throw RecognitionError.apiError(message)
            }
            throw RecognitionError.apiError("Server returned status code \(httpResponse.statusCode)")
        }
        
        // 解析响应
        guard let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw RecognitionError.parseError
        }
        
        guard let candidates = responseDict["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let textPart = parts.first?["text"] as? String else {
            // 检查是否有错误信息
            if let error = responseDict["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw RecognitionError.apiError(message)
            }
            throw RecognitionError.parseError
        }
        
        // 解析JSON响应
        print("📝 Raw API response: \(textPart.prefix(200))...")
        let recognitionResult = try parseResponse(textPart)
        print("✅ Parsed result: productName=\(recognitionResult.productName), price=\(recognitionResult.price?.description ?? "nil")")
        return recognitionResult
    }
    
    // 编码图片为base64
    private func encodeImage(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        return imageData.base64EncodedString()
    }
    
    // 调整图片大小
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // 如果图片已经足够小，直接返回
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // 计算新尺寸，保持宽高比
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        // 重绘图片
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    // 解析API响应
    private func parseResponse(_ jsonString: String) throws -> RecognitionResult {
        // 清理响应文本，移除可能的markdown代码块
        var cleaned = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 移除markdown代码块标记（处理 ```json ... ``` 格式）
        if cleaned.hasPrefix("```") {
            // 移除开头的 ```
            cleaned = String(cleaned.dropFirst(3))
            // 移除可能的语言标识符（如 json）
            if let newlineIndex = cleaned.firstIndex(of: "\n") {
                let afterNewline = String(cleaned[cleaned.index(after: newlineIndex)...])
                cleaned = afterNewline
            }
            // 移除结尾的 ```
            if let closingIndex = cleaned.range(of: "```", options: .backwards) {
                cleaned = String(cleaned[..<closingIndex.lowerBound])
            }
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 尝试找到JSON对象（更安全的方式）
        var jsonText = cleaned
        if let jsonStartRange = cleaned.range(of: "{") {
            let startIndex = jsonStartRange.lowerBound
            // 从第一个 { 开始，找到最后一个匹配的 }
            var braceCount = 0
            var endIndex: String.Index? = nil
            
            for index in cleaned[startIndex...].indices {
                let char = cleaned[index]
                if char == "{" {
                    braceCount += 1
                } else if char == "}" {
                    braceCount -= 1
                    if braceCount == 0 {
                        endIndex = cleaned.index(after: index)
                        break
                    }
                }
            }
            
            if let endIndex = endIndex, endIndex <= cleaned.endIndex {
                jsonText = String(cleaned[startIndex..<endIndex])
            } else {
                // 如果找不到匹配的 }，尝试使用最后一个 }
                if let lastBrace = cleaned.range(of: "}", options: .backwards),
                   lastBrace.upperBound < cleaned.endIndex {
                    let proposedEnd = cleaned.index(after: lastBrace.upperBound)
                    let safeEndIndex = proposedEnd <= cleaned.endIndex ? proposedEnd : cleaned.endIndex
                    jsonText = String(cleaned[startIndex..<safeEndIndex])
                } else if let lastBrace = cleaned.range(of: "}", options: .backwards) {
                    // 如果 } 已经是最后一个字符，直接使用它
                    jsonText = String(cleaned[startIndex...lastBrace.upperBound])
                }
            }
        }
        
        // 尝试解析JSON
        guard let jsonData = jsonText.data(using: .utf8) else {
            throw RecognitionError.parseError
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            // 如果直接解析失败，尝试更宽松的解析
            print("⚠️ Failed to parse JSON directly. Text: \(jsonText)")
            throw RecognitionError.parseError
        }
        
        let productName = json["productName"] as? String ?? "Failed to identify product"
        let priceValue = json["price"]
        
        var price: Double? = nil
        if let priceNumber = priceValue as? NSNumber {
            price = priceNumber.doubleValue
        } else if let priceString = priceValue as? String,
                  !priceString.isEmpty,
                  priceString.lowercased() != "null",
                  let priceDouble = Double(priceString) {
            price = priceDouble
        } else if priceValue is NSNull {
            price = nil
        }
        
        return RecognitionResult(productName: productName, price: price)
    }
}

// 识别错误
enum RecognitionError: LocalizedError {
    case invalidImage
    case apiError(String)
    case parseError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .apiError(let message):
            return message
        case .parseError:
            return "Failed to parse recognition result"
        case .networkError:
            return "Network error, please try again"
        }
    }
}

