import SwiftUI

struct DecisionFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var productName: String = ""
    @State private var price: Double = 0
    
    var onCreate: (Decision) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.white, Color(red: 0.9, green: 0.93, blue: 1.0)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("What are you considering?")
                            .font(.title2).bold()
                            .foregroundStyle(.black.opacity(0.8))
                        
                        // 上传占位
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .foregroundStyle(Color.purple.opacity(0.4))
                            .frame(height: 140)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "arrow.up.to.line.square")
                                        .font(.system(size: 30))
                                        .foregroundStyle(.purple.opacity(0.7))
                                    Text("Drop an image here, or click to select")
                                        .font(.footnote)
                                        .foregroundStyle(.gray)
                                    Text("PNG, JPG up to 10MB")
                                        .font(.caption2)
                                        .foregroundStyle(.gray.opacity(0.6))
                                }
                            )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Product Name")
                                .font(.subheadline).bold()
                            TextField("e.g., iPhone 15 Pro", text: $productName)
                                .padding(14)
                                .background(Color.white)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Price")
                                .font(.subheadline).bold()
                            HStack {
                                Text("$").foregroundStyle(.gray)
                                TextField("0.00", value: $price, format: .number)
                                    .keyboardType(.decimalPad)
                            }
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        Button {
                            let newDecision = Decision(
                                id: UUID(),
                                title: productName.isEmpty ? "New decision" : productName,
                                price: price,
                                date: .now,
                                status: .pending
                            )
                            onCreate(newDecision)
                            dismiss()
                        } label: {
                            Text("Start Conversation")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .disabled(productName.isEmpty)
                        .opacity(productName.isEmpty ? 0.6 : 1)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.black.opacity(0.7))
                    }
                }
            }
        }
    }
}
