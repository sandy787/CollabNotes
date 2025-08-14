//  ChatViewModel.swift
//  CollabNotes
//  Created by prajwal sanap on 08/08/25.

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
            return chat.participants.contains { $0.id != currentUser.id && $0.isOnline }
        } else {
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
    
    
    private func setupSocketListeners() {
        socketService.$newMessage
            .compactMap { $0 }
            .filter { [weak self] message in
                message.chatId == self?.chat.id
            }
            .sink { [weak self] message in
                self?.addMessage(message)
            }
            .store(in: &cancellables)
        
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
                
                socketService.sendMessage(chatId: chat.id, content: content)
                
                
            } catch {
                messageText = originalMessageText
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    
    func startTyping() {
        socketService.sendTypingIndicator(chatId: chat.id, isTyping: true)
        
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
    
    
    private func addMessage(_ message: Message) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard !self.messages.contains(where: { $0.id == message.id }) else { return }
            
            self.messages.append(message)
            self.messages.sort { $0.createdAt < $1.createdAt }
        }
    }
    
    
    func isMessageFromCurrentUser(_ message: Message) -> Bool {
        return message.sender.id == currentUser?.id
    }
    
    func shouldShowSenderName(for message: Message, at index: Int) -> Bool {
        guard chat.isGroup && !isMessageFromCurrentUser(message) else { return false }
        
        if index == 0 {
            return true
        }
        
        let previousMessage = messages[index - 1]
        return previousMessage.sender.id != message.sender.id
    }
    
    func shouldShowTimestamp(for message: Message, at index: Int) -> Bool {
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
