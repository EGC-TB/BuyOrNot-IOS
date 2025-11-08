import SwiftUI
import PhotosUI
import UIKit

struct DecisionFormView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var productName: String = ""
    @State private var price: Double = 0
    @State private var selectedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showActionSheet = false
    @State private var isProcessingImage = false
    @State private var recognitionError: String?
    
    private let recognitionService = ImageRecognitionService(apiKey: "AIzaSyDPc9Lo6WiYgkXaFCgjKMaX_NEQ7gl4-6g")
    
    var onCreate: (Decision, UIImage?) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        titleText
                        imageSelectionArea
                        productNameField
                        priceField
                        startButton
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
                            .foregroundStyle(Color.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(uiColor: .systemBackground),
                Color(uiColor: .secondarySystemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var titleText: some View {
        Text("What are you considering?")
            .font(.title2).bold()
            .foregroundStyle(Color.primary)
    }
    
    private var imageSelectionArea: some View {
        VStack(spacing: 12) {
                            if let image = selectedImage {
                                // 显示选中的图片
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                    
                                    // 加载指示器
                                    if isProcessingImage {
                                        ZStack {
                                            Color.black.opacity(0.3)
                                            VStack(spacing: 8) {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                Text("Analyzing image...")
                                                    .font(.caption)
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                    }
                                    
                                    // 删除和更换按钮
                                    if !isProcessingImage {
                                        HStack {
                                            Button {
                                                showActionSheet = true
                                            } label: {
                                                Image(systemName: "pencil.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(.white)
                                                    .background(Circle().fill(Color.black.opacity(0.5)))
                                            }
                                            
                                            Button {
                                                self.selectedImage = nil
                                                self.selectedPhotoItem = nil
                                                self.recognitionError = nil
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.title2)
                                                    .foregroundStyle(.white)
                                                    .background(Circle().fill(Color.black.opacity(0.5)))
                                            }
                                        }
                                        .padding(8)
                                    }
                                }
                            } else {
                                // 占位符
                                Button {
                                    showActionSheet = true
                                } label: {
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                        .foregroundStyle(Color.purple.opacity(0.4))
                                        .frame(height: 140)
                                        .overlay(
                                            VStack(spacing: 8) {
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 30))
                                                    .foregroundStyle(.purple.opacity(0.7))
                                                Text("Tap to add photo")
                                                    .font(.footnote)
                                                    .foregroundStyle(Color.secondary)
                                                Text("Take photo or choose from library")
                                                    .font(.caption2)
                                                    .foregroundStyle(Color.secondary.opacity(0.8))
                                            }
                                        )
                                }
                            }
                            
                            // 错误消息
                            if let error = recognitionError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .padding(.horizontal)
                            }
                            
                            // 操作按钮（当没有图片时）
                            if selectedImage == nil {
                                HStack(spacing: 12) {
                                    Button {
                                        showCamera = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "camera.fill")
                                            Text("Take Photo")
                                        }
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.purple)
                                        .cornerRadius(12)
                                    }
                                    
                                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                        HStack {
                                            Image(systemName: "photo.on.rectangle")
                                            Text("Choose Photo")
                                        }
                                        .font(.subheadline)
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.pink)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .confirmationDialog("Select Photo", isPresented: $showActionSheet) {
                            Button("Take Photo") {
                                showCamera = true
                            }
                            Button("Choose from Library") {
                                showImagePicker = true
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                        .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotoItem, matching: .images)
                        .sheet(isPresented: $showCamera) {
                            ImagePicker(image: $selectedImage, sourceType: .camera)
                        }
                        .onChange(of: selectedPhotoItem) { oldValue, newValue in
                            if let newValue = newValue {
                                loadImage(from: newValue)
                            }
                        }
                        .onChange(of: selectedImage) { oldValue, newValue in
                            if let newValue = newValue {
                                recognizeImage(newValue)
                            }
                        }
    }
    
    private var productNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Product Name")
                .font(.subheadline).bold()
                .foregroundStyle(Color.primary)
            TextField("e.g., iPhone 15 Pro", text: $productName)
                .padding(14)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var priceField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Price")
                .font(.subheadline).bold()
                .foregroundStyle(Color.primary)
            HStack {
                Text("$").foregroundStyle(Color.secondary)
                TextField("0.00", value: $price, format: .number)
                    .keyboardType(.decimalPad)
            }
            .padding(14)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var startButton: some View {
        Button {
            // 如果产品名是错误消息，使用默认值
            let finalProductName = (productName == "Failed to identify product" || productName.isEmpty) ? "New decision" : productName
            
            let newDecision = Decision(
                id: UUID(),
                title: finalProductName,
                price: price,
                date: .now,
                status: .pending
            )
            onCreate(newDecision, selectedImage)
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
        .disabled(isProcessingImage)
        .opacity(isProcessingImage ? 0.6 : 1)
    }
    
    // 从PhotosPickerItem加载图片
    private func loadImage(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                    recognitionError = nil
                }
            }
        }
    }
    
    // 识别图片
    private func recognizeImage(_ image: UIImage) {
        isProcessingImage = true
        recognitionError = nil
        
        Task {
            do {
                print("🔍 Starting image recognition...")
                let result = try await recognitionService.recognizeProduct(from: image)
                print("✅ Recognition result: \(result.productName), price: \(result.price?.description ?? "nil")")
                
                await MainActor.run {
                    if result.productName == "Failed to identify product" {
                        productName = "Failed to identify product"
                        recognitionError = "Could not identify product. Please enter manually."
                    } else {
                        productName = result.productName
                    }
                    
                    if let extractedPrice = result.price {
                        price = extractedPrice
                    }
                    
                    isProcessingImage = false
                }
            } catch {
                await MainActor.run {
                    isProcessingImage = false
                    let errorMsg = error.localizedDescription
                    print("❌ Recognition error: \(errorMsg)")
                    recognitionError = "Failed to analyze image: \(errorMsg). Please try again or enter manually."
                }
            }
        }
    }
}

// UIImagePickerController的SwiftUI包装器
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
