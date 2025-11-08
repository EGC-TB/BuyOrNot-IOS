//
//  LoginView.swift
//  BuyOrNot
//  Neo - 11/8

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: FirebaseService
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var name: String = ""
    @State private var isSignUp: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var onLoginSuccess: () -> Void
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 标题和logo
                    VStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        Text("BuyOrNot")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    
                    // Form
                    VStack(spacing: 20) {
                        if isSignUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                TextField("Enter your name", text: $name)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.footnote)
                                .fontWeight(.semibold)
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.footnote)
                                .fontWeight(.semibold)
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }
                        
                        // Submit button
                        Button {
                            Task {
                                await handleSubmit()
                            }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isSignUp ? "Sign Up" : "Sign In")
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
                        .disabled(isLoading || email.isEmpty || password.isEmpty || (isSignUp && name.isEmpty))
                        .opacity(isLoading || email.isEmpty || password.isEmpty || (isSignUp && name.isEmpty) ? 0.6 : 1.0)
                        
                        // 切换登录/注册
                        Button {
                            withAnimation {
                                isSignUp.toggle()
                                errorMessage = nil
                            }
                        } label: {
                            HStack {
                                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                    .foregroundStyle(.secondary)
                                Text(isSignUp ? "Sign In" : "Sign Up")
                                    .foregroundStyle(.purple)
                                    .fontWeight(.semibold)
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }
    
    // 处理登录/注册
    private func handleSubmit() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if isSignUp {
                try await authService.signUp(email: email, password: password, name: name)
            } else {
                try await authService.signIn(email: email, password: password)
            }
            onLoginSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(14)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

