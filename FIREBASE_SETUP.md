# Firebase Setup Guide for BuyOrNot

This guide will help you set up Firebase Authentication and Firestore for the BuyOrNot iOS app.

## Prerequisites

1. A Firebase account (sign up at https://firebase.google.com)
2. Xcode installed on your Mac
3. CocoaPods or Swift Package Manager (SPM) - we'll use SPM

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Follow the setup wizard:
   - Enter project name: "BuyOrNot" (or your preferred name)
   - Enable/disable Google Analytics (optional)
   - Click "Create project"

## Step 2: Add iOS App to Firebase

1. In Firebase Console, click the iOS icon (or "Add app")
2. Enter your iOS bundle ID:
   - Find it in Xcode: Select your project → General tab → Bundle Identifier
   - Example: `com.yourname.BuyOrNot`
3. Enter App nickname (optional): "BuyOrNot iOS"
4. Enter App Store ID (optional, can skip)
5. Click "Register app"

## Step 3: Download GoogleService-Info.plist

1. Download the `GoogleService-Info.plist` file from Firebase Console
2. **Important**: Add this file to your Xcode project

### 详细步骤：如何添加 GoogleService-Info.plist 到 Xcode

#### 方法 1: 使用菜单栏（如果右键菜单没有选项）

1. **打开 Xcode 项目**
   - 双击 `BuyOrNot.xcodeproj` 打开项目

2. **找到 BuyOrNot 文件夹**
   - 在 Xcode 左侧的 Project Navigator（项目导航器）中
   - 找到蓝色的 `BuyOrNot` 文件夹（这是你的主项目文件夹）
   - **点击选中这个文件夹**（重要：要先选中）

3. **使用菜单栏添加文件**
   - 在 Xcode 顶部菜单栏，点击 **File**
   - 在下拉菜单中找到 **Add Files to "BuyOrNot"...**
   - 点击它

4. **选择文件**
   - 会打开一个文件选择对话框
   - 找到你下载的 `GoogleService-Info.plist` 文件（通常在 Downloads 文件夹）
   - 点击选择它

5. **重要设置 - 在弹出窗口中：**
   - ✅ **勾选 "Copy items if needed"** - 这会把文件复制到项目中
   - ✅ **在 "Add to targets" 部分，勾选 "BuyOrNot"** - 这确保文件被包含在构建中
   - 点击 **"Add"** 按钮

6. **验证文件已添加**
   - 在 Project Navigator 中，你应该能看到 `GoogleService-Info.plist` 文件出现在 `BuyOrNot` 文件夹下
   - 点击这个文件，在右侧的 File Inspector 中，确认 "Target Membership" 中 "BuyOrNot" 被勾选 ✅

**注意：** 如果右键菜单中没有 "Add Files to BuyOrNot..."，使用上面的菜单栏方法。或者直接使用方法 2（拖拽），更简单！

#### 方法 2: 直接拖拽（最简单，推荐！）

1. **打开 Xcode 和 Finder**
   - 在 Xcode 中打开项目
   - 在 Finder 中找到下载的 `GoogleService-Info.plist` 文件

2. **拖拽文件**
   - 从 Finder 中拖拽 `GoogleService-Info.plist` 文件
   - 拖到 Xcode 左侧 Project Navigator 中的 `BuyOrNot` 文件夹上
   - 松开鼠标

3. **在弹出窗口中设置**
   - ✅ **勾选 "Copy items if needed"**
   - ✅ **勾选 "Add to targets: BuyOrNot"**
   - 点击 **"Finish"**

#### 验证文件是否正确添加

1. **检查文件位置**
   - 在 Project Navigator 中，`GoogleService-Info.plist` 应该在 `BuyOrNot` 文件夹下
   - 文件名应该是蓝色的（表示是源文件）

2. **检查 Target Membership（最简单的方法）**

   **快速验证方法（推荐）：**
   - 在 Xcode 左侧 Project Navigator 中，点击 `GoogleService-Info.plist` 文件
   - 按快捷键：**⌥⌘1** (Option + Command + 1)
   - 右侧会弹出 Inspector 面板
   - 在右侧面板顶部，点击最左边的图标（File Inspector 图标）
   - 向下滚动，找到 **"Target Membership"** 部分
   - 确保 **"BuyOrNot"** 前面的复选框被勾选 ✅
   
   **如果右侧面板没有显示：**
   - 方法 1：按 **⌥⌘1** (Option + Command + 1)
   - 方法 2：在菜单栏选择 **View → Inspectors → Show File Inspector**
   - 方法 3：在 Xcode 右上角，点击最右边的图标（两个重叠的矩形）
   
   **如果还是找不到 Target Membership：**
   - 不用担心！只要文件是蓝色的（在 Project Navigator 中），通常就已经正确添加了
   - 更简单的验证：直接运行应用，如果不再崩溃，说明文件已经正确添加 ✅

3. **检查文件内容（可选）**
   - 点击文件，在编辑器中查看
   - 应该能看到类似这样的内容：
     ```xml
     <?xml version="1.0" encoding="UTF-8"?>
     <plist version="1.0">
     <dict>
         <key>CLIENT_ID</key>
         ...
     ```
   - 如果能看到这些内容，说明文件正确

#### 如果遇到问题

**问题：文件添加后看不到？**
- 确保文件在 `BuyOrNot` 文件夹下，不是子文件夹
- 尝试清理构建：Product → Clean Build Folder (⇧⌘K)

**问题：应用仍然找不到文件？**
- 检查 Target Membership 是否勾选
- 删除文件并重新添加
- 确保 "Copy items if needed" 被勾选

**问题：文件是红色的？**
- 这表示文件路径有问题
- 删除文件，确保 "Copy items if needed" 被勾选，然后重新添加

## Step 4: Add Firebase SDK via Swift Package Manager

1. In Xcode, go to **File → Add Package Dependencies...**
2. Enter the Firebase iOS SDK URL:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
3. Click "Add Package"
4. Select the following products (you can select all, but these are the minimum required):
   - ✅ **FirebaseAuth** (for authentication)
   - ✅ **FirebaseFirestore** (for database)
   - ✅ **FirebaseCore** (required base)
5. Click "Add Package"
6. Make sure your app target is selected and click "Finish"

## Step 5: Enable Authentication in Firebase Console

1. In Firebase Console, go to **Authentication** → **Get started**
2. Click on **Sign-in method** tab
3. Enable **Email/Password**:
   - Click on "Email/Password"
   - Toggle "Enable" to ON
   - Click "Save"

## Step 6: Set Up Firestore Database

1. In Firebase Console, go to **Firestore Database** → **Create database**
2. Choose **Start in test mode** (for development)
   - **Important**: For production, set up proper security rules
3. Select a location for your database (choose closest to your users)
4. Click "Enable"

## Step 7: Configure Firestore Security Rules (Important!)

1. In Firebase Console, go to **Firestore Database** → **Rules**
2. Replace the default rules with these (for development):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

3. Click "Publish"

**⚠️ Security Note**: The above rules allow authenticated users to only access their own data. For production, you may want to add more specific rules.

## Step 8: Build and Run

1. In Xcode, clean build folder: **Product → Clean Build Folder** (⇧⌘K)
2. Build the project: **Product → Build** (⌘B)
3. Run the app: **Product → Run** (⌘R)

## Step 9: Test the App

1. When you run the app, you should see the login screen
2. Click "Sign Up" to create a new account
3. Enter:
   - Name: Your name
   - Email: A valid email address
   - Password: At least 6 characters
4. Click "Sign Up"
5. You should be logged in and see the main dashboard

## Troubleshooting

### Error: "GoogleService-Info.plist not found"
- Make sure `GoogleService-Info.plist` is added to your Xcode project
- Check that it's included in your app target (Target Membership)
- Verify the file is in the correct location (BuyOrNot folder)

### Error: "FirebaseApp.configure()" crashes
- Make sure Firebase SDK packages are properly added
- Clean build folder and rebuild
- Check that `GoogleService-Info.plist` has correct bundle ID

### Authentication not working
- Verify Email/Password is enabled in Firebase Console
- Check that you're using a valid email format
- Ensure password is at least 6 characters

### Data not syncing
- Check Firestore rules allow read/write for authenticated users
- Verify you're logged in (check Firebase Console → Authentication)
- Check Xcode console for error messages

## Data Structure in Firestore

Your data will be stored in Firestore with this structure:

```
users/
  {userId}/
    name: string
    email: string
    savedAmount: number
    decisions/
      {decisionId}/
        id: string
        title: string
        price: number
        date: timestamp
        status: string (pending/skipped/purchased)
    expenses/
      {expenseId}/
        id: string
        name: string
        price: number
        date: timestamp
        decisionId: string (optional)
```

## Next Steps

- Set up proper Firestore security rules for production
- Consider adding email verification
- Add password reset functionality
- Set up Firebase Analytics (optional)
- Configure Firebase Crashlytics (optional)

## Support

If you encounter issues:
1. Check Firebase Console for error logs
2. Check Xcode console for Swift errors
3. Verify all steps above were completed correctly
4. Ensure your internet connection is working

