# 🛍️ BuyOrNot (SmartBuy)

**BuyOrNot** is a smart spending decision assistant built with SwiftUI.
It helps you reflect on purchases before making them, track your expenses, and visualize your savings — powered by a conversational AI interface.

---

## 📱 Features

### 💬 Chat-Based Decision Assistant

* Discuss potential purchases with an AI chatbot that helps you think before you buy.
* Get suggestions or reflections based on your budget, spending history, and needs.
* Choose to **Buy** or **Not**, with visual feedback and automatic tracking.

### 💸 Expense Tracking

* Every purchase decision is saved automatically.
* Bought items appear in your **Expenses** list and contribute to your total **Spent** amount.
* Skipped purchases add their value to your **Saved** total.

### 📊 Dashboard Overview

* Get a clear, gradient-based dashboard showing:

  * Total **Spent**
  * Total **Saved**
  * Quick access to **New Decision**, **Expense Tracker**, and **Account**

### 📂 Decision History

* View all past decisions with visual cards:

  * **Purchased** cards in green
  * **Skipped** cards in red
* Instantly reopen any decision for further chat or review.

---

## 🧠 Core Logic

| Action            | Result                                           |
| ----------------- | ------------------------------------------------ |
| **Buy**           | Adds item to expenses, increases “Spent”         |
| **Not**           | Marks decision as skipped, adds price to “Saved” |
| **New Decision**  | Opens a form to record a potential purchase      |
| **Chat Decision** | Discuss item in ChatBotView, then decide         |

---

## 🧩 Architecture Overview

### Main Components

| File                       | Description                               |
| -------------------------- | ----------------------------------------- |
| `RootView.swift`           | App’s main navigation and state manager   |
| `DashboardView.swift`      | Displays overall statistics and key cards |
| `ChatBotView.swift`        | Conversational purchase assistant         |
| `DecisionFormView.swift`   | Form to add a new decision                |
| `ExpenseTrackerView.swift` | Lists all purchases                       |
| `DecisionCardView.swift`   | Visual component for a decision item      |
| `ExpenseItem.swift`        | Model representing a purchase             |
| `Decision.swift`           | Model for each buy/not decision           |
| `AccountView.swift`        | (Optional) User profile view              |

---

## ⚙️ Data Model

```swift
struct Decision: Identifiable {
    var id: UUID
    var title: String
    var price: Double
    var date: Date
    var status: DecisionStatus
}

enum DecisionStatus: String, Codable {
    case pending
    case purchased
    case skipped
}

struct ExpenseItem: Identifiable {
    var id: UUID
    var name: String
    var price: Double
    var date: Date
}
```

---

## 🧱 Tech Stack

* **Language:** Swift
* **Framework:** SwiftUI
* **Architecture:** MVVM-style state management using `@State` and `@Binding`
* **Asynchronous Logic:** `async/await` for chat responses
* **UI Design:** Gradient-based adaptive cards and light theme
* **Data:** In-memory state (no persistence yet)

---

## 🚀 Getting Started

1. **Clone the Repository**

   ```bash
   git clone https://github.com/yourname/BuyOrNot.git
   cd BuyOrNot
   ```

2. **Open in Xcode**

   ```bash
   open BuyOrNot.xcodeproj
   ```

3. **Run the App**

   * Select an iPhone simulator.
   * Press **Run (⌘ + R)**.

---

## 🧩 Future Improvements

* 🔗 Integrate OpenAI API for smarter chat logic
* 💾 Persistent local storage with CoreData or SwiftData
* 📈 Analytics dashboard (spending vs saving trends)
* 🌙 Dark mode support
* 🪙 Custom budget goals and recommendations

---

## 🧑‍💻 Author

**Eagle** — Developer, Researcher, and Deep Learning Enthusiast

> Interested in making tech that improves decision-making and financial wellness.
