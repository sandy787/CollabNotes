//
//  SocketService.swift
//  CollabNotes
//
//  Created by prajwal sanap on 08/08/25.
//

import Foundation
import Combine
import SocketIO // - Add this dependency via Xcode Package Manager

/*
 To add Socket.io dependency:
 1. In Xcode, go to File > Add Package Dependencies
 2. Add: https://github.com/socketio/socket.io-client-swift
 3. Version: 16.0.0 or later
 4. Uncomment the import above and the SocketIO code below
*/

class SocketService: ObservableObject {
    static let shared = SocketService()
    
    private let keychainService = KeychainService.shared
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    @Published var isConnected = false
    @Published var connectionError: String?
    
    // Message events
    @Published var newMessage: Message?
    @Published var userTypingInChat: (chatId: String, user: User, isTyping: Bool)?
    
    // User presence events
    @Published var userOnline: User?
    @Published var userOffline: User?
    
    // Note events
    @Published var noteUpdated: Note?
    @Published var userTypingInNote: (chatId: String, user: User, isTyping: Bool)?
    
    private init() {}
    
    // MARK: - Connection Management
    
    func connect() {
        guard let token = keychainService.getJWTToken() else {
            connectionError = "No authentication token"
            return
        }
        
        guard let url = URL(string: APIConfig.socketURL) else {
            connectionError = "Invalid socket URL"
            return
        }
        
        manager = SocketManager(socketURL: url, config: [
            .log(false),
            .compress,
            .extraHeaders(["Authorization": "Bearer \(token)"]),
            .connectParams(["token": token])
        ])
        
        socket = manager?.defaultSocket
        
        setupEventHandlers()
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    // MARK: - Event Handlers Setup
    
    private func setupEventHandlers() {
        // Connection events
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.isConnected = true
                self?.connectionError = nil
            }
        }
        
        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.isConnected = false
            }
        }
        
        socket?.on(clientEvent: .error) { [weak self] data, _ in
            DispatchQueue.main.async {
                self?.connectionError = "Connection error: \(data)"
            }
        }
        
        // Message events
        socket?.on(SocketEvents.newMessage) { [weak self] data, _ in
            if let messageData = data.first as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: messageData),
               let message = try? JSONDecoder().decode(Message.self, from: jsonData) {
                DispatchQueue.main.async {
                    self?.newMessage = message
                }
            }
        }
        
        socket?.on(SocketEvents.userTypingMessage) { [weak self] data, _ in
            if let typingData = data.first as? [String: Any],
               let chatId = typingData["chatId"] as? String,
               let isTyping = typingData["isTyping"] as? Bool,
               let userData = typingData["user"] as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: userData),
               let user = try? JSONDecoder().decode(User.self, from: jsonData) {
                DispatchQueue.main.async {
                    self?.userTypingInChat = (chatId, user, isTyping)
                }
            }
        }
        
        // User presence events
        socket?.on(SocketEvents.userOnline) { [weak self] data, _ in
            if let userData = data.first as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: userData),
               let user = try? JSONDecoder().decode(User.self, from: jsonData) {
                DispatchQueue.main.async {
                    self?.userOnline = user
                }
            }
        }
        
        socket?.on(SocketEvents.userOffline) { [weak self] data, _ in
            if let userData = data.first as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: userData),
               let user = try? JSONDecoder().decode(User.self, from: jsonData) {
                DispatchQueue.main.async {
                    self?.userOffline = user
                }
            }
        }
        
        // Note events
        socket?.on(SocketEvents.noteUpdated) { [weak self] data, _ in
            if let noteData = data.first as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: noteData),
               let note = try? JSONDecoder().decode(Note.self, from: jsonData) {
                DispatchQueue.main.async {
                    self?.noteUpdated = note
                }
            }
        }
        
        socket?.on(SocketEvents.userTypingNote) { [weak self] data, _ in
            if let typingData = data.first as? [String: Any],
               let chatId = typingData["chatId"] as? String,
               let isTyping = typingData["isTyping"] as? Bool,
               let userData = typingData["user"] as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: userData),
               let user = try? JSONDecoder().decode(User.self, from: jsonData) {
                DispatchQueue.main.async {
                    self?.userTypingInNote = (chatId, user, isTyping)
                }
            }
        }
    }
    
    // MARK: - Emit Events
    
    func joinChats(chatIds: [String]) {
        socket?.emit(SocketEvents.joinChats, chatIds)
    }
    
    func sendMessage(chatId: String, content: String) {
        socket?.emit(SocketEvents.sendMessage, [
            "chatId": chatId,
            "content": content
        ])
    }
    
    func sendTypingIndicator(chatId: String, isTyping: Bool) {
        socket?.emit(SocketEvents.typingMessage, [
            "chatId": chatId,
            "isTyping": isTyping
        ])
    }
    
    func updateNote(chatId: String, content: String, version: Int) {
        socket?.emit(SocketEvents.updateNote, [
            "chatId": chatId,
            "content": content,
            "version": version
        ])
    }
    
    func sendNoteTypingIndicator(chatId: String, isTyping: Bool) {
        socket?.emit(SocketEvents.typingNote, [
            "chatId": chatId,
            "isTyping": isTyping
        ])
    }
    
    // MARK: - Helper Methods
    
    func clearMessages() {
        newMessage = nil
        userTypingInChat = nil
        userOnline = nil
        userOffline = nil
        noteUpdated = nil
        userTypingInNote = nil
    }
}
