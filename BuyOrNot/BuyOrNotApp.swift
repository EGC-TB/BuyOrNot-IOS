import SwiftUI
import FirebaseCore

@main
struct BuyOrNotApp: App {
    @StateObject private var authService = FirebaseService()
    
    init() {
        // 检查 GoogleService-Info.plist 是否存在
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           FileManager.default.fileExists(atPath: path) {
            // 初始化 Firebase
            FirebaseApp.configure()
        } else {
            // 如果文件不存在，打印错误信息
            print("⚠️ 错误: 找不到 GoogleService-Info.plist 文件!")
            print("请按照以下步骤操作:")
            print("1. 在 Firebase Console 创建项目")
            print("2. 添加 iOS 应用")
            print("3. 下载 GoogleService-Info.plist")
            print("4. 将文件拖到 Xcode 项目的 BuyOrNot 文件夹中")
            print("5. 确保 'Copy items if needed' 被选中")
            print("6. 确保 'BuyOrNot' target 被选中")
            
            // 在开发环境中，仍然尝试配置（可能会崩溃，但会显示更清晰的错误）
            #if DEBUG
            fatalError("GoogleService-Info.plist 文件缺失。请按照上面的说明添加文件。")
            #else
            // 生产环境：尝试配置，如果失败就失败
            FirebaseApp.configure()
            #endif
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                RootView()
                    .environmentObject(authService)
            } else {
                LoginView(onLoginSuccess: {
                    // Login success is handled automatically by authService.isAuthenticated
                })
                .environmentObject(authService)
            }
        }
    }
}
