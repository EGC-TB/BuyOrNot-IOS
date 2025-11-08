//
//  expense tracker.swift
//  BuyOrNot
//
//  Created by Eagle Chen on 11/7/25.
//

import SwiftUI

struct ExpenseTrackerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: FirebaseService
    @Binding var expenses: [ExpenseItem]
    
    @StateObject private var dataManager = FirebaseDataManager()
    @State private var showAdd = false
    @State private var newName: String = ""
    @State private var newPrice: Double = 0
    
    private var total: Double {
        expenses.reduce(0) { $0 + $1.price }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.white, Color(red: 0.9, green: 0.93, blue: 1.0)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Total Spent")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                        HStack {
                            Text("$\(total, specifier: "%.2f")")
                                .font(.title)
                                .bold()
                            Spacer()
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.green)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    Button {
                        withAnimation {
                            showAdd.toggle()
                        }
                    } label: {
                        Text(showAdd ? "Cancel" : "+ Add New Purchase")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .padding(.horizontal)
                    }
                    
                    if showAdd {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Item Name")
                                .font(.footnote).bold()
                            TextField("e.g., Coffee Maker", text: $newName)
                                .padding(12)
                                .background(.white)
                                .cornerRadius(16)
                            
                            Text("Price")
                                .font(.footnote).bold()
                            HStack {
                                Text("$")
                                TextField("0.00", value: $newPrice, format: .number)
                                    .keyboardType(.decimalPad)
                            }
                            .padding(12)
                            .background(.white)
                            .cornerRadius(16)
                            
                            HStack {
                                Button("Add") {
                                    let newItem = ExpenseItem(id: UUID(), decisionId: nil, name: newName, price: newPrice, date: .now)
                                    expenses.insert(newItem, at: 0)
                                    // 保存到Firebase
                                    if let userId = authService.currentUserId {
                                        Task {
                                            try? await dataManager.saveExpense(newItem, userId: userId)
                                        }
                                    }
                                    newName = ""
                                    newPrice = 0
                                    withAnimation { showAdd = false }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.pink)
                                .foregroundStyle(.white)
                                .cornerRadius(14)
                                
                                Button("Cancel") {
                                    withAnimation { showAdd = false }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(.white)
                                .cornerRadius(14)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(expenses) { expense in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(expense.name)
                                            .font(.headline)
                                        Text(expense.date, style: .date)
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                    }
                                    Spacer()
                                    Text("$\(expense.price, specifier: "%.2f")")
                                        .bold()
                                    Button {
                                        if let idx = expenses.firstIndex(of: expense) {
                                            let expenseToDelete = expenses[idx]
                                            expenses.remove(at: idx)
                                            // 从Firebase删除
                                            if let userId = authService.currentUserId {
                                                Task {
                                                    try? await dataManager.deleteExpense(expenseToDelete, userId: userId)
                                                }
                                            }
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red)
                                    }
                                }
                                .padding()
                                .background(.white)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack(alignment: .leading) {
                        Text("Expense Tracker")
                            .font(.headline)
                        Text("Keep track of what you bought")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.black.opacity(0.7))
                    }
                }
            }
        }
    }
}
