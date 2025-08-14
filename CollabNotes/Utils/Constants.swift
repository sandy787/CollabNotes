//  Constants.swift
//  CollabNotes
//  Created by prajwal sanap on 08/08/25.

import Foundation

struct APIConfig {
    static let baseURL = "https://server-production-b292.up.railway.app"
    static let socketURL = "wss://server-production-b292.up.railway.app"
    
    struct Endpoints {
        static let register = "/api/auth/register"
        static let login = "/api/auth/login"
        static let me = "/api/auth/me"
        static let chats = "/api/chats"
        static func messages(chatId: String) -> String { "/api/messages/\(chatId)" }
        static func notes(chatId: String) -> String { "/api/notes/\(chatId)" }
    }
}

struct KeychainKeys {
    static let jwtToken = "jwt_token"
    static let userID = "user_id"
}

struct SocketEvents {
    static let joinChats = "join-chats"
    static let sendMessage = "send-message"
    static let typingMessage = "typing-message"
    static let updateNote = "update-note"
    static let typingNote = "typing-note"
    
    static let newMessage = "new-message"
    static let userOnline = "user-online"
    static let userOffline = "user-offline"
    static let userTypingMessage = "user-typing-message"
    static let userTypingNote = "user-typing-note"
    static let noteUpdated = "note-updated"
    static let error = "error"
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case invalidResponse
    case unauthorized
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response"
        case .unauthorized:
            return "Unauthorized access"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}
