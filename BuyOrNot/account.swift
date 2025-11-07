//
//  account.swift
//  BuyOrNot
//
//  Created by Eagle Chen on 11/7/25.
//

import SwiftUI

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = "Jane Doe"
    @State private var email: String = "jane.doe@example.com"
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.white, Color(red: 0.92, green: 0.93, blue: 1.0)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Button {
                            // TODO: 打开照片选择
                        } label: {
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 40))
                                    )
                                Circle()
                                    .fill(.white)
                                    .frame(width: 34, height: 34)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .foregroundStyle(.purple)
                                    )
                                    .offset(x: 4, y: 4)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Name")
                                .font(.footnote).bold()
                            TextField("Name", text: $name)
                                .padding(14)
                                .background(.white)
                                .cornerRadius(16)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Email")
                                .font(.footnote).bold()
                            TextField("Email", text: $email)
                                .padding(14)
                                .background(.white)
                                .cornerRadius(16)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Stats")
                                .font(.headline)
                            HStack(spacing: 30) {
                                VStack {
                                    Text("0")
                                        .font(.title3).bold()
                                        .foregroundStyle(.purple)
                                    Text("Decisions").font(.caption)
                                }
                                VStack {
                                    Text("$0")
                                        .font(.title3).bold()
                                        .foregroundStyle(.green)
                                    Text("Saved").font(.caption)
                                }
                                VStack {
                                    Text("$0")
                                        .font(.title3).bold()
                                        .foregroundStyle(.red)
                                    Text("Spent").font(.caption)
                                }
                            }
                            .padding()
                            .background(.white)
                            .cornerRadius(20)
                        }
                        
                        Spacer(minLength: 30)
                    }
                    .padding(20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Account Settings")
                        .font(.headline)
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
