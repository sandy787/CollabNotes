//  NoteViewModel.swift
//  CollabNotes
//  Created by prajwal sanap on 08/08/25.

import Foundation
import Combine

class NoteViewModel: ObservableObject {
    @Published var note: Note?
    @Published var noteContent = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var typingUsers: [User] = []
    @Published var lastSavedAt: Date?
    
    let chatId: String
    private let apiService = APIService.shared
    private let socketService = SocketService.shared
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    private var saveTimer: Timer?
    private var typingTimer: Timer?
    private var lastKnownVersion = 0
    
    var currentUser: User? {
        authService.currentUser
    }
    
    var lastEditedInfo: String {
        guard let note = note,
              let lastEditedBy = note.lastEditedBy else {
            return ""
        }
        
        let isCurrentUser = lastEditedBy.id == currentUser?.id
        let userName = isCurrentUser ? "You" : lastEditedBy.name
        let timeAgo = note.updatedAt.timeAgoDisplay()
        
        return "Last edited by \(userName) \(timeAgo)"
    }
    
    var collaboratorNames: String {
        guard let note = note else { return "" }
        
        let names = note.collaborators.compactMap { collaborator in
            let isCurrentUser = collaborator.user.id == currentUser?.id
            return isCurrentUser ? "You" : collaborator.user.name
        }
        
        if names.count <= 2 {
            return names.joined(separator: " and ")
        } else {
            let firstTwo = names.prefix(2).joined(separator: ", ")
            let remainingCount = names.count - 2
            return "\(firstTwo) and \(remainingCount) other\(remainingCount > 1 ? "s" : "")"
        }
    }
    
    init(chatId: String) {
        self.chatId = chatId
        setupSocketListeners()
        setupAutoSave()
        Task {
            await loadNote()
        }
    }
    
    
    private func setupSocketListeners() {
        socketService.$noteUpdated
            .compactMap { $0 }
            .filter { [weak self] note in
                note.chatId == self?.chatId
            }
            .sink { [weak self] updatedNote in
                self?.handleRemoteNoteUpdate(updatedNote)
            }
            .store(in: &cancellables)
        
        socketService.$userTypingInNote
            .compactMap { $0 }
            .filter { [weak self] (chatId, _, _) in
                chatId == self?.chatId
            }
            .sink { [weak self] (_, user, isTyping) in
                self?.updateTypingStatus(user: user, isTyping: isTyping)
            }
            .store(in: &cancellables)
    }
    
    
    private func setupAutoSave() {
        $noteContent
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] content in
                self?.autoSaveNote()
            }
            .store(in: &cancellables)
    }
    
    
    @MainActor
    func loadNote() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response: NoteResponse = try await apiService.request(
                    endpoint: APIConfig.Endpoints.notes(chatId: chatId),
                    method: .GET
                )
                
                note = response.note
                noteContent = response.note.content
                lastKnownVersion = response.note.version
                
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
    
    
    private func autoSaveNote() {
        guard !noteContent.isEmpty,
              noteContent != note?.content,
              !isSaving else { return }
        
        Task {
            await saveNote()
        }
    }
    
    @MainActor
    func saveNote() {
        guard !isSaving else { return }
        
        isSaving = true
        
        Task {
            do {
                let request = UpdateNoteRequest(
                    content: noteContent,
                    version: lastKnownVersion
                )
                let requestData = try apiService.encode(request)
                
                let response: NoteResponse = try await apiService.request(
                    endpoint: APIConfig.Endpoints.notes(chatId: chatId),
                    method: .PUT,
                    body: requestData
                )
                
                socketService.updateNote(
                    chatId: chatId,
                    content: noteContent,
                    version: lastKnownVersion
                )
                
                note = response.note
                lastKnownVersion = response.note.version
                lastSavedAt = Date()
                
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isSaving = false
        }
    }
    
    
    private func handleRemoteNoteUpdate(_ updatedNote: Note) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if updatedNote.version > self.lastKnownVersion {
                self.note = updatedNote
                self.noteContent = updatedNote.content
                self.lastKnownVersion = updatedNote.version
            }
        }
    }
    
    
    func startTyping() {
        socketService.sendNoteTypingIndicator(chatId: chatId, isTyping: true)
        
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            self?.stopTyping()
        }
    }
    
    func stopTyping() {
        typingTimer?.invalidate()
        socketService.sendNoteTypingIndicator(chatId: chatId, isTyping: false)
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
    
    
    var typingText: String {
        guard !typingUsers.isEmpty else { return "" }
        
        if typingUsers.count == 1 {
            return "\(typingUsers[0].name) is editing..."
        } else if typingUsers.count == 2 {
            return "\(typingUsers[0].name) and \(typingUsers[1].name) are editing..."
        } else {
            return "Several people are editing..."
        }
    }
    
    var saveStatusText: String {
        if isSaving {
            return "Saving..."
        } else if let lastSavedAt = lastSavedAt {
            return "Saved \(lastSavedAt.timeAgoDisplay())"
        } else {
            return ""
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    deinit {
        stopTyping()
        saveTimer?.invalidate()
    }
}
