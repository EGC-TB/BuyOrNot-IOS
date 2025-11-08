import SwiftUI

protocol ChatService {
    func send(message: String, for decision: Decision) async throws -> String
}
import SwiftUI

private let GOOGLE_API_KEY = "AIzaSyDPc9Lo6WiYgkXaFCgjKMaX_NEQ7gl4-6g"

struct GoogleChatService: ChatService {
    func send(message: String, for decision: Decision) async throws -> String {

        let url = URL(string:
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=\(GOOGLE_API_KEY)"
        )!

        let systemPrompt = """
        You are a friendly personal finance advisor helping the user decide whether to buy a product. Respond in a conversational, human-like, middle-length format (about two sentences) — concise, polite (but not overly), and direct. Use the user’s financial profile and goals to guide your reasoning. Ask thoughtful questions about whether the purchase is necessary, aligns with their goals, and reflects genuine needs rather than impulse. Avoid giving direct commands; instead, help the user reach their own decision logically. When asked to make a decision, base it on the user’s information and recent conversation context. Only respond to topics relevant to their financial situation and goals, ignoring unrelated requests.
        """

        let payload: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": systemPrompt],
                        ["text": "Item: \(decision.title), Price: \(decision.price)"],
                        ["text": message]
                    ]
                ]
            ]
        ]

        let body = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)

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
}


struct ChatBotView: View {
    let decision: Decision
    var service: ChatService = GoogleChatService()
    
    // 👇 外面要的两个回调
    var onBuy: (Decision) -> Void
    var onSkip: (Decision) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    
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
                    LinearGradient(colors: [
                        Color(red: 0.98, green: 0.96, blue: 1.0),
                        Color(red: 0.9, green: 0.94, blue: 1.0)
                    ], startPoint: .top, endPoint: .bottom)
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
            let priceString = String(format: "%.2f", decision.price)
            messages.append(
                ChatMessage(role: .assistant,
                            text: "I see you're considering \(decision.title) for $\(priceString). Is this something you need or just want?")
            )
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
                    Text(decision.title).font(.headline)
                    Text("$\(decision.price, specifier: "%.2f")").font(.caption).foregroundStyle(.gray)
                }
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.black.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white)
    }
    
    private var decisionBar: some View {
        HStack(spacing: 12) {
            Button {
                var d = decision
                d.status = .purchased
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
                .foregroundStyle(.gray)
            
            Button {
                var d = decision
                d.status = .skipped
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
    
    private var bottomInput: some View {
        HStack(spacing: 12) {
            TextField("Type your answer...", text: $inputText, axis: .vertical)
                .padding(12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 40))
            
            Button {
                sendMessage()
            } label: {
                Circle()
                    .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "paperplane.fill").foregroundStyle(.white))
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white)
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        messages.append(ChatMessage(role: .user, text: text))
        
        Task {
            do {
                let reply = try await service.send(message: text, for: decision)
                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, text: reply))
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, text: "Network error"))
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
        Text(message.text)
            .padding(14)
            .background(
                message.role == .assistant ? AnyView(Color.white) : AnyView(Color.blue)
            )
            .foregroundStyle(message.role == .assistant ? .black : .white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: message.role == .assistant ? .black.opacity(0.04) : .clear, radius: 3, x: 0, y: 2)
            .frame(maxWidth: 260, alignment: message.role == .assistant ? .leading : .trailing)
    }
}
