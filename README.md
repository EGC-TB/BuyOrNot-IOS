![image](https://github.com/EGC-TB/BuyOrNot-IOS/blob/main/BuyOrNot.png)
# BuyOrNot

BuyOrNot is a smart spending decision assistant iOS app built with SwiftUI and Firebase. It helps users make informed purchase decisions through an AI-powered chat interface, tracks expenses, and visualizes savings.

## Features

### Authentication
- Email and password authentication via Firebase Auth
- User registration with name and email
- Secure login and logout functionality
- User profile management

### Decision Making
- Create new purchase decisions with product name and price
- AI-powered chat assistant (Google Gemini) to discuss purchases
- Make Buy or Not decisions with visual feedback
- Track decision history with status (pending, purchased, skipped)

### Expense Tracking
- Automatic expense creation when items are purchased
- Manual expense entry
- View all expenses with total spent calculation
- Delete expenses with Firebase sync

### Financial Overview
- Dashboard showing total spent and total saved
- Real-time calculation of savings from skipped purchases
- User statistics (decisions count, saved amount, spent amount)
- Visual cards for quick access to features

### Data Persistence
- All data stored in Firebase Firestore
- Real-time synchronization across devices
- Automatic data loading on app launch
- User profile persistence

## Tech Stack

- Language: Swift 5.0
- Framework: SwiftUI
- Backend: Firebase (Authentication, Firestore)
- AI Service: Google Gemini API
- Architecture: MVVM-style with ObservableObject
- Async/Await: For network operations and Firebase calls

## Project Structure

### Core App Files

**BuyOrNotApp.swift**
- Main app entry point
- Initializes Firebase
- Manages authentication state
- Routes between LoginView and RootView

**ContentView.swift (RootView)**
- Main view controller after authentication
- Manages app state (decisions, expenses, user data)
- Handles data loading from Firebase
- Coordinates navigation between views
- Implements decision reconciliation logic

### Authentication

**LoginView.swift**
- Login and signup interface
- Email/password authentication
- Form validation
- Error handling

**FirebaseService.swift**
- Firebase Authentication wrapper
- User sign up, sign in, sign out
- Authentication state management
- Current user information access

### Data Management

**FirebaseDataManager.swift**
- Firestore operations
- CRUD operations for decisions, expenses, user profile
- Real-time listeners for data synchronization
- Data persistence and retrieval

### Views

**DashboardView.swift**
- Main dashboard display
- Shows total spent and saved
- Quick access buttons (New Decision, Expenses)
- Decision cards list
- User avatar with initials

**AccountView.swift**
- User profile settings
- Edit name and email
- Save profile changes to Firebase
- Display user statistics
- Logout functionality

**DecisionFormView.swift**
- Form to create new purchase decisions
- Product name and price input
- Image upload placeholder (future feature)

**DecisionCardView.swift**
- Visual card component for decisions
- Displays decision title, price, date
- Status indicator (Saved badge for skipped items)

**ExpenseTrackerView.swift**
- List of all expenses
- Total spent calculation
- Add new expenses manually
- Delete expenses
- Firebase synchronization

**ChatBotView.swift**
- AI chat interface for purchase discussions
- Google Gemini API integration
- Message history display
- Buy/Not decision buttons
- Real-time chat responses

**GradientCardView.swift**
- Reusable gradient card component
- Used for quick action buttons
- Customizable colors and content

### Models

**Decision.swift**
- Purchase decision model
- Properties: id, title, price, date, status
- Status enum: pending, skipped, purchased
- Codable for Firebase serialization

**ExpenseItem.swift**
- Expense model
- Properties: id, decisionId, name, price, date
- Links expenses to decisions
- Codable for Firebase serialization

**ChatMessage.swift**
- Chat message model
- Properties: id, role (user/assistant), text, time
- Used in chatbot conversation

## Setup Instructions

### Prerequisites

1. Xcode 15.0 or later
2. iOS 18.5 or later deployment target
3. Firebase account
4. Google Gemini API key (for chat functionality)

### Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Add iOS app with your bundle identifier
3. Download GoogleService-Info.plist
4. Add GoogleService-Info.plist to Xcode project:
   - Drag file into BuyOrNot folder
   - Ensure "Copy items if needed" is checked
   - Ensure "BuyOrNot" target is selected
5. Enable Email/Password authentication in Firebase Console
6. Create Firestore database in test mode
7. Set up Firestore security rules (see FIREBASE_SETUP.md)

### Dependencies

Add Firebase SDK via Swift Package Manager:

1. In Xcode: File > Add Package Dependencies
2. Enter: https://github.com/firebase/firebase-ios-sdk
3. Select packages:
   - FirebaseCore
   - FirebaseAuth
   - FirebaseFirestore
4. Add to BuyOrNot target

### API Configuration

Update the Google Gemini API key in chatbot.swift:

```swift
private let GOOGLE_API_KEY = "YOUR_API_KEY_HERE"
```

Get API key from: https://makersuite.google.com/app/apikey

### Build and Run

1. Open BuyOrNot.xcodeproj in Xcode
2. Select target device or simulator
3. Build project (Command + B)
4. Run app (Command + R)

## Data Structure

### Firestore Collections

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

## Core Workflows

### User Registration

1. User enters name, email, password
2. FirebaseService.signUp creates Firebase Auth user
3. Name saved to Firebase Auth displayName
4. Profile saved to Firestore
5. User redirected to dashboard

### Creating a Decision

1. User taps "New Decision" button
2. DecisionFormView opens
3. User enters product name and price
4. Decision created with status "pending"
5. Saved to Firestore
6. ChatBotView opens automatically

### Making a Decision

1. User chats with AI about purchase
2. User taps "Buy" or "Not" button
3. Decision status updated
4. If Buy: expense created, saved amount unchanged
5. If Not: saved amount increases by price
6. Changes synced to Firebase

### Expense Management

1. Purchased decisions automatically create expenses
2. User can manually add expenses in ExpenseTrackerView
3. Expenses can be deleted
4. All changes sync to Firebase in real-time

## Security Rules

Firestore security rules should be configured as:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

This ensures users can only access their own data.

## Troubleshooting

### App Crashes on Launch

- Verify GoogleService-Info.plist is in project
- Check file is included in target membership
- Ensure Firebase packages are properly installed

### Authentication Not Working

- Verify Email/Password is enabled in Firebase Console
- Check network connection
- Verify email format is valid
- Ensure password is at least 6 characters

### Data Not Syncing

- Check Firestore rules allow read/write
- Verify user is authenticated
- Check Xcode console for error messages
- Ensure Firestore database is created

### Chat Not Working

- Verify Google Gemini API key is set
- Check API key has proper permissions
- Verify network connection
- Check API quota limits

## File Descriptions

- BuyOrNotApp.swift: App initialization and routing
- ContentView.swift: Main view controller and state management
- LoginView.swift: Authentication interface
- DashboardView.swift: Main dashboard display
- AccountView.swift: User profile and settings
- DecisionFormView.swift: New decision creation form
- DecisionCardView.swift: Decision card component
- ExpenseTrackerView.swift: Expense list and management
- ChatBotView.swift: AI chat interface
- GradientCardView.swift: Reusable gradient card
- FirebaseService.swift: Authentication service
- FirebaseDataManager.swift: Firestore data operations
- Decision.swift: Decision data model
- ExpenseItem.swift: Expense data model
- ChatMessage.swift: Chat message model

## Development Notes

- All Firebase operations are async/await
- Real-time listeners update UI automatically
- Data is persisted immediately on changes
- User authentication state is observed throughout app
- Chinese comments added for key functions

## License

This project is private and proprietary.

## Author

Yinuo Chen, Yong Li Neo, Miaomiao Shu - AI@ATL 2025
