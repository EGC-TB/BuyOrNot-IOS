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

1. Download the `GoogleService-Info.plist` file
2. **Important**: Add this file to your Xcode project:
   - Open your project in Xcode
   - Right-click on the `BuyOrNot` folder in Project Navigator
   - Select "Add Files to BuyOrNot..."
   - Select the downloaded `GoogleService-Info.plist`
   - **Make sure "Copy items if needed" is checked**
   - **Make sure "BuyOrNot" target is selected**
   - Click "Add"

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

