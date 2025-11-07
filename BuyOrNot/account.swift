import SwiftUI

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var name: String
    @Binding var email: String
    
    let decisionsCount: Int
    let savedAmount: Double
    let spentAmount: Double
    
    // ✅ Helper to compute initials dynamically
    private var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.white, Color(red: 0.92, green: 0.93, blue: 1.0)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Button {
                            // Future: upload profile image
                        } label: {
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(LinearGradient(colors: [.purple, .pink],
                                                         startPoint: .topLeading,
                                                         endPoint: .bottomTrailing))
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Text(initials) // 👈 show initials
                                            .foregroundStyle(.white)
                                            .font(.system(size: 36, weight: .bold))
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
                            Text("Name").font(.footnote).bold()
                            TextField("Name", text: $name)
                                .padding(14)
                                .background(.white)
                                .cornerRadius(16)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Email").font(.footnote).bold()
                            TextField("Email", text: $email)
                                .padding(14)
                                .background(.white)
                                .cornerRadius(16)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Stats").font(.headline)
                            HStack(spacing: 30) {
                                VStack {
                                    Text("\(decisionsCount)")
                                        .font(.title3).bold()
                                        .foregroundStyle(.purple)
                                    Text("Decisions").font(.caption)
                                }
                                VStack {
                                    Text("$\(savedAmount, specifier: "%.0f")")
                                        .font(.title3).bold()
                                        .foregroundStyle(.green)
                                    Text("Saved").font(.caption)
                                }
                                VStack {
                                    Text("$\(spentAmount, specifier: "%.0f")")
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
                    Text("Account Settings").font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.black.opacity(0.7))
                    }
                }
            }
        }
    }
}
