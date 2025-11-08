import SwiftUI

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: FirebaseService
    
    @Binding var name: String
    @Binding var email: String
    
    let decisionsCount: Int
    let savedAmount: Double
    let spentAmount: Double
    
    @StateObject private var dataManager = FirebaseDataManager()
    @State private var showSaveConfirmation: Bool = false
    @State private var isSaving: Bool = false
    
    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.white, Color(red: 0.92, green: 0.93, blue: 1.0)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 头像
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Text(initials)
                                        .foregroundStyle(.white)
                                        .font(.system(size: 38, weight: .bold))
                                )
                            Circle()
                                .fill(.white)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .foregroundStyle(.purple)
                                )
                                .offset(x: 4, y: 4)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Name").font(.footnote).bold()
                            TextField("Name", text: $name)
                                .padding(14)
                                .background(.white)
                                .cornerRadius(16)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Email").font(.footnote).bold()
                            TextField("Email", text: $email)
                                .padding(14)
                                .background(.white)
                                .cornerRadius(16)
                                .keyboardType(.emailAddress)
                        }
                        
                        Button {
                            saveProfile()
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Changes")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(
                                LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundStyle(.white)
                            .cornerRadius(16)
                        }
                        .disabled(isSaving || name.isEmpty || email.isEmpty)
                        .opacity(isSaving || name.isEmpty || email.isEmpty ? 0.6 : 1.0)
                        .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Stats").font(.headline)
                            HStack(spacing: 30) {
                                VStack {
                                    Text("\(decisionsCount)")
                                        .font(.title3).bold().foregroundStyle(.purple)
                                    Text("Decisions").font(.caption)
                                }
                                VStack {
                                    Text("$\(savedAmount, specifier: "%.0f")")
                                        .font(.title3).bold().foregroundStyle(.green)
                                    Text("Saved").font(.caption)
                                }
                                VStack {
                                    Text("$\(spentAmount, specifier: "%.0f")")
                                        .font(.title3).bold().foregroundStyle(.red)
                                    Text("Spent").font(.caption)
                                }
                            }
                            .padding()
                            .background(.white)
                            .cornerRadius(20)
                        }
                        
                        // 登出按钮
                        Button {
                            logout()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Log Out")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.red.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.top, 20)
                        
                        Spacer(minLength: 30)
                    }
                    .padding(20)
                }
            }
            .overlay(alignment: .top) {
                if showSaveConfirmation {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Changes saved!")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.top, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: showSaveConfirmation)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Account Settings")
                        .font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.black.opacity(0.7))
                    }
                }
            }
        }
    }
    
    // 保存用户信息
    private func saveProfile() {
        guard let userId = authService.currentUserId else { return }
        
        isSaving = true
        Task {
            do {
                try await dataManager.saveUserProfile(name: name, email: email, userId: userId)
                showSaveConfirmation = true
                
                // 2秒后隐藏确认消息
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSaveConfirmation = false
                }
            } catch {
                print("Error saving profile: \(error)")
            }
            isSaving = false
        }
    }
    
    // 登出
    private func logout() {
        do {
            try authService.signOut()
            dismiss() // 关闭账户页面
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
