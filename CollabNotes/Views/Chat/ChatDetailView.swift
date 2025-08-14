//  ChatDetailView.swift
//  CollabNotes
//  Created by prajwal sanap on 08/08/25.

import SwiftUI

struct ChatDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ChatViewModel
    @StateObject private var socketService = SocketService.shared
    @State private var showingNoteView = false
    @FocusState private var isMessageFieldFocused: Bool
    
    init(chat: Chat) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(chat: chat))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                messagesView
                
                if !viewModel.typingText.isEmpty {
                    typingIndicatorView
                }
                
                messageInputView
            }
            .navigationTitle(viewModel.chatDisplayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingNoteView = true
                        }) {
                            Label("Shared Note", systemImage: "doc.text")
                        }
                        
                        Button(action: {
                        }) {
                            Label("Chat Info", systemImage: "info.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onAppear {
                socketService.connect()
            }
            .onDisappear {
                viewModel.stopTyping()
            }
            .sheet(isPresented: $showingNoteView) {
                NoteView(chatId: viewModel.chat.id)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    
    private var messagesView: some View {
        Group {
            if viewModel.isLoadingMessages {
                loadingView
            } else if viewModel.messages.isEmpty {
                emptyMessagesView
            } else {
                messagesList
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading messages...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyMessagesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "message")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No messages yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Start the conversation!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                        MessageBubbleView(
                            message: message,
                            isFromCurrentUser: viewModel.isMessageFromCurrentUser(message),
                            showSenderName: viewModel.shouldShowSenderName(for: message, at: index),
                            showTimestamp: viewModel.shouldShowTimestamp(for: message, at: index)
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color.chatBackground)
            .onChange(of: viewModel.messages.count) { _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                if let lastMessage = viewModel.messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
    
    
    private var typingIndicatorView: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 6, height: 6)
                        .scaleEffect(1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: true
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.messageReceived)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.chatBackground)
    }
    
    
    private var messageInputView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                TextField("Message", text: $viewModel.messageText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .focused($isMessageFieldFocused)
                    .onChange(of: viewModel.messageText) { _ in
                        if !viewModel.messageText.isEmpty {
                            viewModel.startTyping()
                        }
                    }
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.messageText.trimmed.isEmpty ? .secondary : .blue)
                }
                .disabled(viewModel.messageText.trimmed.isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
    }
}


struct MessageBubbleView: View {
    let message: Message
    let isFromCurrentUser: Bool
    let showSenderName: Bool
    let showTimestamp: Bool
    
    var body: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
            if showSenderName {
                Text(message.sender.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            HStack {
                if isFromCurrentUser {
                    Spacer(minLength: 60)
                }
                
                Text(message.content)
                    .messageBubbleStyle(isFromCurrentUser: isFromCurrentUser)
                
                if !isFromCurrentUser {
                    Spacer(minLength: 60)
                }
            }
            
            if showTimestamp {
                Text(message.createdAt.messageTimeDisplay())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 2)
    }
}


#Preview {
    let sampleUser = User(
        id: "1",
        email: "demo@example.com",
        name: "Demo User",
        avatar: nil,
        isOnline: true,
        lastSeen: Date()
    )
    
    let sampleMessage = Message(
        id: "1",
        chatId: "chat1",
        sender: sampleUser,
        content: "Hello there!",
        messageType: "text",
        createdAt: Date(),
        editedAt: nil,
        readBy: nil
    )
    
    let sampleChat = Chat(
        id: "chat1",
        name: nil,
        participants: [sampleUser],
        isGroup: false,
        lastMessage: sampleMessage,
        lastActivity: Date(),
        createdAt: Date(),
        updatedAt: Date()
    )
    
    ChatDetailView(chat: sampleChat)
}
