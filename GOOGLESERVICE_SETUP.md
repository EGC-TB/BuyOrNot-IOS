# 如何添加 GoogleService-Info.plist

## 问题
应用崩溃，错误信息显示找不到 `GoogleService-Info.plist` 文件。

## 解决步骤

### 1. 在 Firebase Console 创建项目（如果还没有）

1. 访问 [Firebase Console](https://console.firebase.google.com/)
2. 点击 "Add project" 或选择现有项目
3. 输入项目名称：`BuyOrNot`
4. 按照向导完成创建

### 2. 添加 iOS 应用到 Firebase

1. 在 Firebase Console 中，点击 iOS 图标（或 "Add app"）
2. 输入 Bundle ID：
   - 在 Xcode 中查看：选择项目 → General → Bundle Identifier
   - 应该是：`eagle.BuyOrNot`
3. 输入 App nickname（可选）：`BuyOrNot iOS`
4. App Store ID（可选，可以跳过）
5. 点击 "Register app"

### 3. 下载 GoogleService-Info.plist

1. 在 Firebase Console 的设置页面，你会看到 "Download GoogleService-Info.plist"
2. 点击下载按钮
3. 文件会下载到你的下载文件夹

### 4. 将文件添加到 Xcode 项目

**方法 A: 拖拽（推荐）**
1. 打开 Xcode 项目
2. 在 Finder 中找到下载的 `GoogleService-Info.plist` 文件
3. 将文件拖拽到 Xcode 的 Project Navigator 中的 `BuyOrNot` 文件夹
4. **重要**: 在弹出窗口中：
   - ✅ 勾选 "Copy items if needed"
   - ✅ 确保 "Add to targets: BuyOrNot" 被选中
   - 点击 "Finish"

**方法 B: 使用菜单**
1. 在 Xcode 中，右键点击 `BuyOrNot` 文件夹
2. 选择 "Add Files to BuyOrNot..."
3. 选择下载的 `GoogleService-Info.plist` 文件
4. **重要**: 确保勾选：
   - ✅ "Copy items if needed"
   - ✅ "Add to targets: BuyOrNot"
5. 点击 "Add"

### 5. 验证文件已添加

1. 在 Xcode 的 Project Navigator 中，你应该能看到 `GoogleService-Info.plist` 文件
2. 点击文件，在右侧的 File Inspector 中：
   - 确保 "Target Membership" 中 "BuyOrNot" 被勾选 ✅

### 6. 重新运行应用

1. 清理构建：Product → Clean Build Folder (⇧⌘K)
2. 重新构建：Product → Build (⌘B)
3. 运行应用：Product → Run (⌘R)

## 验证

如果一切正常：
- 应用应该不再崩溃
- 你应该能看到登录界面
- 控制台不应该有 Firebase 配置错误

## 常见问题

**Q: 文件已添加但应用仍然崩溃？**
- 检查文件是否在正确的 target 中（Target Membership）
- 清理构建文件夹并重新构建
- 重启 Xcode

**Q: 找不到 Bundle ID？**
- 在 Xcode 中：选择项目 → General tab → Bundle Identifier
- 应该是 `eagle.BuyOrNot`

**Q: 文件在项目中但应用找不到？**
- 确保文件在 `BuyOrNot` 文件夹中（不是子文件夹）
- 检查 Target Membership 设置
- 尝试删除文件并重新添加

## 下一步

添加文件后，继续设置 Firebase：
1. 在 Firebase Console 启用 Authentication（Email/Password）
2. 创建 Firestore 数据库
3. 设置安全规则

参考 `FIREBASE_SETUP.md` 获取完整设置指南。

