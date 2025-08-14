//
//  ChatViewModel.swift
//  CollabNotes
//
//  Created by prajwal sanap on 08/08/25.
//

import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText = ""
    @Published var isLoading = false
    @Published var isLoadingMessages = false
    @Published var errorMessage: String?
    @Published var typingUsers: [User] = []
    
    let chat: Chat
    private let apiService = APIService.shared
    private let socketService = SocketService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    private var typingTimer: Timer?
    
    var currentUser: User? {
        authService.currentUser
    }
    
    var chatDisplayName: String {
        guard let currentUser = currentUser else {
            return chat.name ?? "Chat"
        }
        
        if chat.isGroup {
            return chat.name ?? "Group Chat"
        } else {
            let otherParticipant = chat.participants.first { $0.id != currentUser.id }
            return otherParticipant?.name ?? "Unknown User"
        }
    }
    
    var isOnline: Bool {
        guard let currentUser = currentUser else { return false }
        
        if chat.isGroup {
            // For group chats, show if any other participant is online
            return chat.participants.contains { $0.id != currentUser.id && $0.isOnline }
        } else {
            // For direct chats, show the other participant's status
            let otherParticipant = chat.participants.first { $0.id != currentUser.id }
            return otherParticipant?.isOnline ?? false
        }
    }
    
    init(chat: Chat) {
        self.chat = chat
        setupSocketListeners()
        Task {
            await loadMessages()
        }
    }
    
    // MARK: - Socket Listeners
    
    private func setupSocketListeners() {
        // Listen for new messages in this chat
        socketService.$newMessage
            .compactMap { $0 }
            .filter { [weak self] message in
                message.chatId == self?.chat.id
            }
            .sink { [weak self] message in
                self?.addMessage(message)
            }
            .store(in: &cancellables)
        
        // Listen for typing indicators
        socketService.$userTypingInChat
            .compactMap { $0 }
            .filter { [weak self] (chatId, _, _) in
                chatId == self?.chat.id
            }
            .sink { [weak self] (_, user, isTyping) in
                self?.updateTypingStatus(user: user, isTyping: isTyping)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Message Loading
    
    @MainActor
    func loadMessages() {
        isLoadingMessages = true
        errorMessage = nil
        
        Task {
            do {
                let response: MessagesResponse = try await apiService.request(
                    endpoint: APIConfig.Endpoints.messages(chatId: chat.id),
                    method: .GET
                )
                
                messages = response.messages.sorted { $0.createdAt < $1.createdAt }
                
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoadingMessages = false
        }
    }
    
    // MARK: - Message Sending
    
    @MainActor
    func sendMessage() {
        let content = messageText.trimmed
        guard !content.isEmpty, !isLoading else { return }
        
        isLoading = true
        let originalMessageText = messageText
        messageText = "" // Clear immediately for better UX
        
        Task {
            do {
                let request = SendMessageRequest(content: content)
                let requestData = try apiService.encode(request)
                
                let response: MessageResponse = try await apiService.request(
                    endpoint: APIConfig.Endpoints.messages(chatId: chat.id),
                    method: .POST,
                    body: requestData
                )
                
                // Also emit via socket for real-time delivery
                socketService.sendMessage(chatId: chat.id, content: content)
                
                // Message will be added via socket listener or we can add it directly
                // addMessage(response.message)
                
            } catch {
                // Restore message text on error
                messageText = originalMessageText
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Typing Indicators
    
    func startTyping() {
        socketService.sendTypingIndicator(chatId: chat.id, isTyping: true)
        
        // Reset timer
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.stopTyping()
        }
    }
    
    func stopTyping() {
        typingTimer?.invalidate()
        socketService.sendTypingIndicator(chatId: chat.id, isTyping: false)
    }
    
    private func updateTypingStatus(user: User, isTyping: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Don't show current user's typing
            guard user.id != self.currentUser?.id else { return }
            
            if isTyping {
                if !self.typingUsers.contains(where: { $0.id == user.id }) {
                    self.typingUsers.append(user)
                }
            } else {
                self.typingUsers.removeAll { $0.id == user.id }
            }
        }
    }
    
    // MARK: - Message Management
    
    private func addMessage(_ message: Message) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Avoid duplicates
            guard !self.messages.contains(where: { $0.id == message.id }) else { return }
            
            self.messages.append(message)
            self.messages.sort { $0.createdAt < $1.createdAt }
        }
    }
    
    // MARK: - Helper Methods
    
    func isMessageFromCurrentUser(_ message: Message) -> Bool {
        return message.sender.id == currentUser?.id
    }
    
    func shouldShowSenderName(for message: Message, at index: Int) -> Bool {
        // Always show for group chats, unless it's from current user
        guard chat.isGroup && !isMessageFromCurrentUser(message) else { return false }
        
        // Show if it's the first message or if the previous message is from a different sender
        if index == 0 {
            return true
        }
        
        let previousMessage = messages[index - 1]
        return previousMessage.sender.id != message.sender.id
    }
    
    func shouldShowTimestamp(for message: Message, at index: Int) -> Bool {
        // Show timestamp if it's the last message or if the next message is from a different sender or more than 5 minutes later
        guard index < messages.count - 1 else { return true }
        
        let nextMessage = messages[index + 1]
        let timeDifference = nextMessage.createdAt.timeIntervalSince(message.createdAt)
        
        return nextMessage.sender.id != message.sender.id || timeDifference > 300 // 5 minutes
    }
    
    var typingText: String {
        guard !typingUsers.isEmpty else { return "" }
        
        if typingUsers.count == 1 {
            return "\(typingUsers[0].name) is typing..."
        } else if typingUsers.count == 2 {
            return "\(typingUsers[0].name) and \(typingUsers[1].name) are typing..."
        } else {
            return "Several people are typing..."
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    deinit {
        stopTyping()
    }
}
