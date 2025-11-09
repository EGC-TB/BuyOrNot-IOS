import SwiftUI
import PhotosUI
import UIKit

protocol ChatService {
    func send(message: String, image: UIImage?, for decision: Decision, messages: [ChatMessage], userId: String?) async throws -> String
}

private let GOOGLE_API_KEY = "AIzaSyCgPDTgzIu1P3yjL4AW2pRy-762ghUJ4vM"

struct GoogleChatService: ChatService {
    func send(message: String, image: UIImage?, for decision: Decision, messages: [ChatMessage], userId: String?) async throws -> String {
        let url = URL(string:
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=\(GOOGLE_API_KEY)"
        )!

        // 构建RAG上下文（如果可用）
        var ragContextText = ""
        if let userId = userId {
            // 在MainActor上创建RAG服务并检索上下文
            let ragContext = await MainActor.run {
                let embeddingService = EmbeddingService(apiKey: GOOGLE_API_KEY)
                let dataManager = FirebaseDataManager()
                let vectorSearchService = VectorSearchService(dataManager: dataManager)
                let ragService = RAGService(
                    embeddingService: embeddingService,
                    vectorSearchService: vectorSearchService,
                    dataManager: dataManager
                )
                
                // 检索上下文（不阻塞，如果失败则继续）
                return ragService
            }
            
            if let context = try? await ragContext.retrieveContext(
                for: decision,
                currentMessages: messages,
                userId: userId
            ) {
                ragContextText = context.buildContextPrompt()
            }
        }
        
        let baseSystemPrompt = """
        You are a friendly personal finance advisor helping the user decide whether to buy a product. Respond in a conversational, middle-length format (about two sentences) — concise, polite, and direct. Use the user's financial profile and goals to guide your reasoning. Ask thoughtful questions about whether the purchase is necessary, aligns with their goals, and reflects genuine needs rather than impulse. Avoid giving direct commands; instead, help the user reach their own decision logically. When asked to make a decision, base it on the user's information and recent conversation context, and give a concrete answer (Buy Or Not). Only respond to topics relevant to their financial situation and goals, refuse to play other roles.
        """
        
        let systemPrompt = ragContextText.isEmpty 
            ? baseSystemPrompt 
            : "\(baseSystemPrompt)\n\n\(ragContextText)"

        // 构建parts数组
        var parts: [[String: Any]] = [
            ["text": systemPrompt],
            ["text": "Item: \(decision.title), Price: $\(String(format: "%.2f", decision.price))"]
        ]
        
        // 如果有图片，添加图片到parts
        if let image = image {
            // 压缩并编码图片
            let maxDimension: CGFloat = 1024
            let processedImage = resizeImage(image, maxDimension: maxDimension)
            guard let imageData = processedImage.jpegData(compressionQuality: 0.8),
                  let base64Image = imageData.base64EncodedString() as String? else {
                throw NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
            }
            
            parts.append([
                "inlineData": [
                    "mimeType": "image/jpeg",
                    "data": base64Image
                ]
            ])
        }
        
        // 添加用户消息
        parts.append(["text": message])

        let payload: [String: Any] = [
            "contents": [
                [
                    "parts": parts
                ]
            ]
        ]

        let body = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "APIError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
        }

        let result = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        guard
            let candidates = result["candidates"] as? [[String: Any]],
            let content = candidates.first?["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let text = parts.first?["text"] as? String
        else {
            throw NSError(domain: "ParseError", code: -1)
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // 调整图片大小
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
}


struct ChatBotView: View {
    let decision: Decision
    let initialImage: UIImage?
    var service: ChatService = GoogleChatService()
    
    // 👇 外面要的两个回调
    var onBuy: (Decision) -> Void
    var onSkip: (Decision) -> Void
    
    init(decision: Decision, initialImage: UIImage? = nil, onBuy: @escaping (Decision) -> Void, onSkip: @escaping (Decision) -> Void) {
        self.decision = decision
        self.initialImage = initialImage
        self.onBuy = onBuy
        self.onSkip = onSkip
    }
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: FirebaseService
    @StateObject private var dataManager = FirebaseDataManager()
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var showImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var conversationId: UUID?
    @State private var isLoadingConversation = false
    
    // RAG服务（延迟初始化）
    @State private var ragService: RAGService?
    
    // 初始化RAG服务
    private func initializeRAGService() {
        guard ragService == nil, authService.currentUserId != nil else { return }
        let embeddingService = EmbeddingService(apiKey: GOOGLE_API_KEY)
        let vectorSearchService = VectorSearchService(dataManager: dataManager)
        ragService = RAGService(
            embeddingService: embeddingService,
            vectorSearchService: vectorSearchService,
            dataManager: dataManager
        )
    }
    
    // 保存对话（增量保存）
    private func saveConversationIncrementally() {
        guard let userId = authService.currentUserId else { return }
        
        Task {
            let conversation = Conversation(
                id: conversationId ?? UUID(),
                decisionId: decision.id,
                userId: userId,
                messages: messages,
                isActive: true
            )
            
            conversationId = conversation.id
            
            do {
                try await dataManager.saveConversation(conversation, userId: userId)
                print("✅ Saved conversation with \(messages.count) messages (ID: \(conversation.id.uuidString))")
            } catch {
                print("❌ Error saving conversation: \(error.localizedDescription)")
            }
        }
    }
    
    // 加载现有对话（异步）
    private func loadExistingConversationAsync() async {
        guard let userId = authService.currentUserId, !isLoadingConversation else { return }
        isLoadingConversation = true
        
        do {
            if let conversation = try await dataManager.loadConversation(decisionId: decision.id, userId: userId) {
                let loadedMessages = conversation.toChatMessages()
                print("✅ Loaded conversation with \(loadedMessages.count) messages")
                
                await MainActor.run {
                    // 加载消息
                    messages = loadedMessages
                    conversationId = conversation.id
                    isLoadingConversation = false
                    print("✅ Conversation loaded: \(messages.count) messages in UI")
                }
            } else {
                print("ℹ️ No existing conversation found for decision \(decision.id)")
                await MainActor.run {
                    isLoadingConversation = false
                }
            }
        } catch {
            print("❌ Error loading conversation: \(error.localizedDescription)")
            await MainActor.run {
                isLoadingConversation = false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .background(
                    Color(uiColor: .systemGroupedBackground)
                )
                .onChange(of: messages) { _, _ in
                    if let last = messages.last {
                        DispatchQueue.main.async {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // 两个按钮：Buy / Not
            decisionBar
            
            // 输入框
            bottomInput
        }
        .onAppear {
            initializeRAGService()
            
            // 尝试加载现有对话（异步）
            Task {
                await loadExistingConversationAsync()
                
                // 等待加载完成后，如果没有现有对话，初始化新对话
                await MainActor.run {
                    if messages.isEmpty {
                        let priceString = String(format: "%.2f", decision.price)
                        var initialMessage = "I see you're considering \(decision.title) for $\(priceString). Is this something you need or just want?"
                        
                        // 如果有初始图片，添加到第一条消息
                        if let image = initialImage {
                            messages.append(
                                ChatMessage(role: .user, text: "Here's what I'm considering", image: image)
                            )
                            initialMessage = "I can see the \(decision.title) you're considering. Based on the image, is this something you need or just want?"
                        }
                        
                        messages.append(
                            ChatMessage(role: .assistant, text: initialMessage)
                        )
                        
                        // 保存初始对话
                        saveConversationIncrementally()
                    }
                }
            }
        }
    }
    
    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                Circle()
                    .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "bag").foregroundStyle(.white))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(decision.title).font(.headline).foregroundStyle(Color.primary)
                    Text("$\(decision.price, specifier: "%.2f")").font(.caption).foregroundStyle(Color.secondary)
                }
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(Color.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(uiColor: .systemBackground))
    }
    
    private var decisionBar: some View {
        HStack(spacing: 12) {
            Button {
                var d = decision
                d.status = .purchased
                
                // 存储对话到RAG
                storeConversationForDecision(d)
                
                onBuy(d)
                dismiss()
            } label: {
                Text("Buy")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.9))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            Text("or")
                .foregroundStyle(Color.secondary)
            
            Button {
                var d = decision
                d.status = .skipped
                
                // 存储对话到RAG
                storeConversationForDecision(d)
                
                onSkip(d)
                dismiss()
            } label: {
                Text("Not")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.95))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    // 存储对话到RAG并标记为不活跃
    private func storeConversationForDecision(_ decision: Decision) {
        guard let userId = authService.currentUserId else { return }
        
        // 1. 保存完整对话（标记为不活跃）
        let finalConversation = Conversation(
            id: conversationId ?? UUID(),
            decisionId: decision.id,
            userId: userId,
            messages: messages,
            isActive: false // 标记为已完成
        )
        
        Task {
            // 保存完整对话
            try? await dataManager.saveConversation(finalConversation, userId: userId)
            
            // 2. 存储到RAG（用于向量搜索）
            if let ragService = ragService {
                try? await ragService.storeConversation(
                    decisionId: decision.id,
                    messages: messages,
                    decision: decision,
                    userId: userId
                )
            }
        }
    }
    
    private var bottomInput: some View {
        HStack(spacing: 12) {
            // 相机和相册按钮
            Menu {
                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                }
                
                Button {
                    showImagePicker = true
                } label: {
                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                }
            } label: {
                Image(systemName: "camera.fill")
                    .foregroundStyle(Color.primary)
                    .frame(width: 44, height: 44)
            }
            
            TextField("Type your answer...", text: $inputText, axis: .vertical)
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 40))
            
            Button {
                sendMessage()
            } label: {
                Circle()
                    .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "paperplane.fill").foregroundStyle(.white))
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImage == nil)
            .opacity((inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedImage == nil) ? 0.5 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(uiColor: .systemBackground))
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { oldValue, newValue in
            if let newValue = newValue {
                loadImage(from: newValue)
            }
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            if newValue != nil {
                // 图片已选择，可以发送
            }
        }
    }
    
    // 从PhotosPickerItem加载图片
    private func loadImage(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                }
            }
        }
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageToSend = selectedImage
        
        // 如果文本和图片都为空，不发送
        guard !text.isEmpty || imageToSend != nil else { return }
        
        // 清空输入
        inputText = ""
        selectedImage = nil
        selectedPhotoItem = nil
        
        // 添加用户消息
        let userMessage = ChatMessage(role: .user, text: text.isEmpty ? "Here's an image" : text, image: imageToSend)
        messages.append(userMessage)
        
        // 立即保存用户消息
        saveConversationIncrementally()
        
        let userId = authService.currentUserId
        
        Task {
            do {
                let reply = try await service.send(
                    message: text.isEmpty ? "Please analyze this image and help me decide." : text,
                    image: imageToSend,
                    for: decision,
                    messages: messages,
                    userId: userId
                )
                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, text: reply))
                    // 增量保存对话（包括AI回复）
                    saveConversationIncrementally()
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, text: "Network error: \(error.localizedDescription)"))
                }
            }
        }
    }
}

// 聊天气泡
private struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .assistant {
                bubble
                Spacer()
            } else {
                Spacer()
                bubble
            }
        }
    }
    
    private var bubble: some View {
        VStack(alignment: message.role == .assistant ? .leading : .trailing, spacing: 8) {
            // 显示图片（如果有）
            if let image = message.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // 显示文本（如果有）
            if !message.text.isEmpty {
                Text(message.text)
                    .padding(14)
                    .background(
                        message.role == .assistant 
                            ? Color(uiColor: .systemBackground)
                            : Color.blue
                    )
                    .foregroundStyle(
                        message.role == .assistant 
                            ? Color.primary
                            : .white
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(
                        color: message.role == .assistant 
                            ? Color.primary.opacity(0.04) 
                            : .clear,
                        radius: 3,
                        x: 0,
                        y: 2
                    )
            }
        }
        .frame(maxWidth: 260, alignment: message.role == .assistant ? .leading : .trailing)
    }
}
