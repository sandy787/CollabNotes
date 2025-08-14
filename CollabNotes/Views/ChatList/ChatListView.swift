//  ChatListView.swift
//  CollabNotes
//  Created by prajwal sanap on 08/08/25.

import SwiftUI

struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @StateObject private var authService = AuthService.shared
    @State private var showingNewChatSheet = false
    @State private var selectedChat: Chat?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                
                chatList
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    profileButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    newChatButton
                }
            }
            .refreshable {
                await viewModel.refreshChats()
            }
            .sheet(isPresented: $showingNewChatSheet) {
                NewChatView { chat in
                    selectedChat = chat
                    showingNewChatSheet = false
                }
            }
            .fullScreenCover(item: $selectedChat) { chat in
                ChatDetailView(chat: chat)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search chats...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !viewModel.searchText.isEmpty {
                Button("Clear") {
                    viewModel.searchText = ""
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
        .padding(.top, 8)
    }
    
    
    private var chatList: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredChats.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(viewModel.filteredChats) { chat in
                        ChatRowView(chat: chat) {
                            selectedChat = chat
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading chats...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "message")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No chats yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Start a conversation by creating a new chat")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Create Chat") {
                showingNewChatSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    
    private var profileButton: some View {
        Button(action: {
            authService.logout()
        }) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(authService.currentUser?.name.prefix(1) ?? "?"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(authService.currentUser?.name ?? "User")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("Tap to logout")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var newChatButton: some View {
        Button(action: {
            showingNewChatSheet = true
        }) {
            Image(systemName: "square.and.pencil")
                .font(.title3)
        }
    }
}


struct ChatRowView: View {
    let chat: Chat
    let onTap: () -> Void
    @StateObject private var authService = AuthService.shared
    
    private var displayName: String {
        guard let currentUser = authService.currentUser else {
            return chat.name ?? "Unknown Chat"
        }
        
        if chat.isGroup {
            return chat.name ?? "Group Chat"
        } else {
            let otherParticipant = chat.participants.first { $0.id != currentUser.id }
            return otherParticipant?.name ?? "Unknown User"
        }
    }
    
    private var otherParticipant: User? {
        guard let currentUser = authService.currentUser else { return nil }
        return chat.participants.first { $0.id != currentUser.id }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                avatarView
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(displayName)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let lastMessage = chat.lastMessage {
                            Text(lastMessage.createdAt.chatTimeDisplay())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        if let lastMessage = chat.lastMessage {
                            Text(lastMessage.content)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        } else {
                            Text("No messages yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        
                        Spacer()
                    }
                }
                
                if !chat.isGroup, let participant = otherParticipant, participant.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private var avatarView: some View {
        Group {
            if chat.isGroup {
                ZStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            } else {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(displayName.prefix(1)))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
            }
        }
    }
}


#Preview {
    ChatListView()
}
