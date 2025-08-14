//
//  ChatListViewModel.swift
//  CollabNotes
//
//  Created by prajwal sanap on 08/08/25.
//

import Foundation
import Combine

class ChatListViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var isRefreshing = false
    
    private let apiService = APIService.shared
    private let socketService = SocketService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var filteredChats: [Chat] {
        if searchText.isEmpty {
            return chats
        } else {
            return chats.filter { chat in
                chat.displayName.localizedCaseInsensitiveContains(searchText) ||
                chat.lastMessage?.content.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    init() {
        setupSocketListeners()
        Task {
            await loadChats()
        }
    }
    
    // MARK: - Socket Listeners
    
    private func setupSocketListeners() {
        // Listen for new messages to update chat list
        socketService.$newMessage
            .compactMap { $0 }
            .sink { [weak self] message in
                self?.updateChatWithNewMessage(message)
            }
            .store(in: &cancellables)
        
        // Listen for user presence updates
        socketService.$userOnline
            .compactMap { $0 }
            .sink { [weak self] user in
                self?.updateUserPresence(user: user, isOnline: true)
            }
            .store(in: &cancellables)
        
        socketService.$userOffline
            .compactMap { $0 }
            .sink { [weak self] user in
                self?.updateUserPresence(user: user, isOnline: false)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    @MainActor
    func loadChats() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response: ChatsResponse = try await apiService.request(
                    endpoint: APIConfig.Endpoints.chats,
                    method: .GET
                )
                
                chats = response.chats.sorted { $0.lastActivity > $1.lastActivity }
                
                // Join all chats via socket
                let chatIds = chats.map { $0.id }
                socketService.joinChats(chatIds: chatIds)
                
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    @MainActor
    func refreshChats() {
        isRefreshing = true
        
        Task {
            do {
                let response: ChatsResponse = try await apiService.request(
                    endpoint: APIConfig.Endpoints.chats,
                    method: .GET
                )
                
                chats = response.chats.sorted { $0.lastActivity > $1.lastActivity }
                
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isRefreshing = false
        }
    }
    
    // MARK: - Chat Creation
    
    @MainActor
    func createDirectChat(with user: User) async -> Chat? {
        do {
            let request = CreateChatRequest(
                participantIds: [user.id],
                isGroup: false,
                name: nil
            )
            let requestData = try apiService.encode(request)
            
            let newChat: Chat = try await apiService.request(
                endpoint: APIConfig.Endpoints.chats,
                method: .POST,
                body: requestData
            )
            
            // Add to local list and sort
            chats.append(newChat)
            chats.sort { $0.lastActivity > $1.lastActivity }
            
            // Join the new chat
            socketService.joinChats(chatIds: [newChat.id])
            
            return newChat
            
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    @MainActor
    func createGroupChat(name: String, participantIds: [String]) async -> Chat? {
        do {
            let request = CreateChatRequest(
                participantIds: participantIds,
                isGroup: true,
                name: name
            )
            let requestData = try apiService.encode(request)
            
            let newChat: Chat = try await apiService.request(
                endpoint: APIConfig.Endpoints.chats,
                method: .POST,
                body: requestData
            )
            
            // Add to local list and sort
            chats.append(newChat)
            chats.sort { $0.lastActivity > $1.lastActivity }
            
            // Join the new chat
            socketService.joinChats(chatIds: [newChat.id])
            
            return newChat
            
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Update Methods
    
    private func updateChatWithNewMessage(_ message: Message) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let index = self.chats.firstIndex(where: { $0.id == message.chatId }) {
                let existingChat = self.chats[index]
                
                // Create updated chat with new message
                let updatedChat = Chat(
                    id: existingChat.id,
                    name: existingChat.name,
                    participants: existingChat.participants,
                    isGroup: existingChat.isGroup,
                    lastMessage: message,
                    lastActivity: message.createdAt,
                    createdAt: existingChat.createdAt,
                    updatedAt: message.createdAt
                )
                
                // Replace and re-sort
                self.chats[index] = updatedChat
                self.chats.sort { $0.lastActivity > $1.lastActivity }
            }
        }
    }
    
    private func updateUserPresence(user: User, isOnline: Bool) {
        for (chatIndex, chat) in chats.enumerated() {
            for (participantIndex, participant) in chat.participants.enumerated() {
                if participant.id == user.id {
                    var updatedParticipant = participant
                    // Update online status (would need to modify User struct for this)
                    // For now, we'll rely on fresh data from API calls
                    break
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    func getChatDisplayName(for chat: Chat) -> String {
        guard let currentUser = authService.currentUser else {
            return chat.displayName
        }
        
        if chat.isGroup {
            return chat.name ?? "Group Chat"
        } else {
            // For direct chats, show the other participant's name
            let otherParticipant = chat.participants.first { $0.id != currentUser.id }
            return otherParticipant?.name ?? "Unknown User"
        }
    }
    
    func getOtherParticipant(in chat: Chat) -> User? {
        guard let currentUser = authService.currentUser else { return nil }
        return chat.participants.first { $0.id != currentUser.id }
    }
}
