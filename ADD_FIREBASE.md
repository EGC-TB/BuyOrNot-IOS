# 快速添加 Firebase 依赖

## 方法 1: 在 Xcode 中添加（推荐）

1. **打开 Xcode 项目**
   - 双击 `BuyOrNot.xcodeproj` 打开项目

2. **添加 Firebase 包**
   - 在 Xcode 菜单栏，点击 **File → Add Package Dependencies...**
   - 在搜索框输入：`https://github.com/firebase/firebase-ios-sdk`
   - 点击 **Add Package**

3. **选择需要的模块**
   选择以下产品（必须选择）：
   - ✅ **FirebaseAuth** (认证)
   - ✅ **FirebaseFirestore** (数据库)
   - ✅ **FirebaseCore** (核心，必须)
   
   点击 **Add Package**

4. **确认目标**
   - 确保 **BuyOrNot** target 被选中
   - 点击 **Finish**

5. **等待下载完成**
   - Xcode 会自动下载和集成 Firebase SDK
   - 这可能需要几分钟时间

6. **重新构建项目**
   - 按 **⌘ + B** 构建项目
   - 错误应该消失了

## 方法 2: 使用命令行（高级）

如果你想用命令行添加，可以运行：

```bash
# 这个方法比较复杂，建议使用方法1
```

## 验证安装

安装成功后，你应该能够：
- 编译项目无错误
- 看到 Firebase 模块在 Xcode 的 Package Dependencies 中

## 如果还有问题

1. **清理构建文件夹**：Product → Clean Build Folder (⇧⌘K)
2. **重新构建**：Product → Build (⌘B)
3. **重启 Xcode**：有时需要重启 Xcode

