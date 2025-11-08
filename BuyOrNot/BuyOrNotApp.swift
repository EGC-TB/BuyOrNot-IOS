import SwiftUI
import FirebaseCore

@main
struct BuyOrNotApp: App {
    @StateObject private var authService = FirebaseService()
    
    init() {
        // 加上这个来初始化firebase
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                RootView()
                    .environmentObject(authService)
            } else {
                LoginView(onLoginSuccess: {
                    // no need to do anything here
                })
                .environmentObject(authService)
            }
        }
    }
}