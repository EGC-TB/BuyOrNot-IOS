import SwiftUI

// 后端协议
protocol ChatService {
    func send(message: String, for decision: Decision) async throws -> String
}

// 假实现
struct MockChatService: ChatService {
    func send(message: String, for decision: Decision) async throws -> String {
        try await Task.sleep(nanoseconds: 600_000_000)
        let priceString = String(format: "%.2f", decision.price)
        return "You are considering \(decision.title) for $\(priceString). You said: \(message)"
    }
}

struct ChatBotView: View {
    let decision: Decision
    var service: ChatService = MockChatService()
    
    // 新增两个回调
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
            
            // 决策条
            decisionBar
            
            // 输入框
            bottomInput
        }
        .onAppear {
            let priceString = String(format: "%.2f", decision.price)
            messages.append(
                ChatMessage(
                    role: .assistant,
                    text: "I see you're considering \(decision.title) for $\(priceString). Is this something you need or just want?"
                )
            )
        }
    }
    
    // MARK: - header
    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                Circle()
                    .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "bag")
                            .foregroundStyle(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(decision.title)
                        .font(.headline)
                    Text("$\(decision.price, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.black.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white)
    }
    
    // MARK: - decision bar
    private var decisionBar: some View {
        HStack(spacing: 12) {
            Button {
                // 买了
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
                // 不买 -> skipped
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
        .background(.clear)
    }
    
    // MARK: - input
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
                    .overlay(
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.white)
                    )
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

// MARK: - 气泡
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
                message.role == .assistant
                ? AnyView(Color.white)
                : AnyView(Color.blue)
            )
            .foregroundStyle(message.role == .assistant ? .black : .white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: message.role == .assistant ? .black.opacity(0.04) : .clear, radius: 3, x: 0, y: 2)
            .frame(maxWidth: 260, alignment: message.role == .assistant ? .leading : .trailing)
    }
}
