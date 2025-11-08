//
//  FirebaseService.swift
//  BuyOrNot
//  Neo - 11/8
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
class FirebaseService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var justSignedUpName: String? // 刚注册时的名字，用于立即显示
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        // 监听登录状态变化
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isAuthenticated = user != nil
            }
        }
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // 注册账号
    func signUp(email: String, password: String, name: String) async throws {
        do {
            // 先保存刚注册的名字，确保在认证状态改变前就设置好
            self.justSignedUpName = name
            print("📝 设置刚注册的名字: \(name)")
            
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // 更新用户名字到 Firebase Auth
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            print("✅ 已更新 Auth displayName: \(name)")
            
            // 保存用户信息到 Firestore（确保完成）
            let dataManager = FirebaseDataManager()
            try await dataManager.saveUserProfile(name: name, email: email, userId: result.user.uid)
            print("✅ 已保存到 Firestore: \(name)")
            
            self.user = result.user
            self.isAuthenticated = true
            print("✅ 注册完成，isAuthenticated = true")
        } catch {
            // 如果失败，清除刚注册的名字
            self.justSignedUpName = nil
            self.errorMessage = error.localizedDescription
            print("❌ 注册失败: \(error.localizedDescription)")
            throw error
        }
    }
    
    // 登录
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // 登出
    func signOut() throws {
        try Auth.auth().signOut()
        self.user = nil
        self.isAuthenticated = false
    }
    
    // 当前用户邮箱
    var currentUserEmail: String? {
        return Auth.auth().currentUser?.email
    }
    
    // 当前用户ID
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    // 当前用户名字
    var currentUserName: String? {
        return Auth.auth().currentUser?.displayName
    }
}

