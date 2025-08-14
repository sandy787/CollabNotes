//
//  NewChatView.swift
//  CollabNotes
//
//  Created by prajwal sanap on 08/08/25.
//

import SwiftUI

struct NewChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chatListViewModel = ChatListViewModel.shared ?? ChatListViewModel()
    @State private var searchText = ""
    @State private var selectedUsers: Set<User> = []
    @State private var groupName = ""
    @State private var isCreatingChat = false
    @State private var showingGroupNameAlert = false
    
    let onChatCreated: (Chat) -> Void
    
    // Demo users for testing - replace with actual user search
    private let demoUsers: [User] = [
        User(id: "1", email: "demo@example.com", name: "Demo User", avatar: nil, isOnline: true, lastSeen: Date()),
        User(id: "2", email: "user2@example.com", name: "John Doe", avatar: nil, isOnline: false, lastSeen: Date().addingTimeInterval(-3600)),
        User(id: "3", email: "user3@example.com", name: "Jane Smith", avatar: nil, isOnline: true, lastSeen: Date()),
        User(id: "4", email: "user4@example.com", name: "Bob Wilson", avatar: nil, isOnline: false, lastSeen: Date().addingTimeInterval(-7200))
    ]
    
    private var filteredUsers: [User] {
        if searchText.isEmpty {
            return demoUsers
        } else {
            return demoUsers.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var isGroupChat: Bool {
        selectedUsers.count > 1
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Selected Users (if any)
                if !selectedUsers.isEmpty {
                    selectedUsersView
                }
                
                // Users List
                usersList
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createChat()
                    }
                    .disabled(selectedUsers.isEmpty || isCreatingChat)
                }
            }
            .alert("Group Name", isPresented: $showingGroupNameAlert) {
                TextField("Enter group name", text: $groupName)
                Button("Create") {
                    Task {
                        await createGroupChat()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter a name for your group chat")
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search users...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Selected Users View
    
    private var selectedUsersView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Selected (\(selectedUsers.count))")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(selectedUsers), id: \.id) { user in
                        selectedUserChip(user)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private func selectedUserChip(_ user: User) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.blue)
                .frame(width: 24, height: 24)
                .overlay(
                    Text(String(user.name.prefix(1)))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
            
            Text(user.name)
                .font(.caption)
                .lineLimit(1)
            
            Button(action: {
                selectedUsers.remove(user)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Users List
    
    private var usersList: some View {
        List {
            ForEach(filteredUsers) { user in
                UserRowView(
                    user: user,
                    isSelected: selectedUsers.contains(user)
                ) {
                    toggleUserSelection(user)
                }
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Actions
    
    private func toggleUserSelection(_ user: User) {
        if selectedUsers.contains(user) {
            selectedUsers.remove(user)
        } else {
            selectedUsers.insert(user)
        }
    }
    
    private func createChat() {
        if isGroupChat {
            showingGroupNameAlert = true
        } else if let user = selectedUsers.first {
            Task {
                await createDirectChat(with: user)
            }
        }
    }
    
    @MainActor
    private func createDirectChat(with user: User) async {
        isCreatingChat = true
        
        if let newChat = await chatListViewModel.createDirectChat(with: user) {
            onChatCreated(newChat)
        }
        
        isCreatingChat = false
    }
    
    @MainActor
    private func createGroupChat() async {
        guard !groupName.trimmed.isEmpty else { return }
        
        isCreatingChat = true
        
        let participantIds = Array(selectedUsers).map { $0.id }
        if let newChat = await chatListViewModel.createGroupChat(
            name: groupName.trimmed,
            participantIds: participantIds
        ) {
            onChatCreated(newChat)
        }
        
        isCreatingChat = false
    }
}

// MARK: - User Row View

struct UserRowView: View {
    let user: User
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.blue)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(user.name.prefix(1)))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                // User Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(user.isOnline ? .green : .gray)
                            .frame(width: 8, height: 8)
                        
                        Text(user.isOnline ? "Online" : "Offline")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                } else {
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 1)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ChatListViewModel Extension

extension ChatListViewModel {
    static var shared: ChatListViewModel? {
        // In a real app, you'd use proper dependency injection
        // For now, we'll create a new instance
        return nil
    }
}

// MARK: - Preview

#Preview {
    NewChatView { _ in }
}
