//
//  Message.swift
//  CollabNotes
//
//  Created by prajwal sanap on 08/08/25.
//

import Foundation

struct Message: Codable, Identifiable, Equatable {
    let id: String
    let chatId: String
    let sender: User
    let content: String
    let messageType: String
    let createdAt: Date
    let editedAt: Date?
    let readBy: [ReadStatus]?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case chatId
        case sender
        case content
        case messageType
        case createdAt
        case editedAt
        case readBy
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        chatId = try container.decode(String.self, forKey: .chatId)
        content = try container.decode(String.self, forKey: .content)
        messageType = try container.decode(String.self, forKey: .messageType)
        readBy = try container.decodeIfPresent([ReadStatus].self, forKey: .readBy)
        
        // Handle sender - could be User object or string ID
        if let senderUser = try? container.decode(User.self, forKey: .sender) {
            sender = senderUser
        } else if let senderID = try? container.decode(String.self, forKey: .sender) {
            // Create a placeholder user when only ID is provided
            sender = User(id: senderID, email: "", name: "Unknown User")
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "Could not decode sender"))
        }
        
        let formatter = ISO8601DateFormatter()
        
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = formatter.date(from: createdAtString) ?? Date()
        } else {
            createdAt = Date()
        }
        
        if let editedAtString = try container.decodeIfPresent(String.self, forKey: .editedAt) {
            editedAt = formatter.date(from: editedAtString)
        } else {
            editedAt = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(chatId, forKey: .chatId)
        try container.encode(sender, forKey: .sender)
        try container.encode(content, forKey: .content)
        try container.encode(messageType, forKey: .messageType)
        try container.encodeIfPresent(readBy, forKey: .readBy)
        
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
        if let editedAt = editedAt {
            try container.encode(formatter.string(from: editedAt), forKey: .editedAt)
        }
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Convenience initializer for creating Message instances
    init(id: String, chatId: String, sender: User, content: String, messageType: String = "text", createdAt: Date = Date(), editedAt: Date? = nil, readBy: [ReadStatus]? = nil) {
        self.id = id
        self.chatId = chatId
        self.sender = sender
        self.content = content
        self.messageType = messageType
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.readBy = readBy
    }
}

struct ReadStatus: Codable {
    let user: String
    let readAt: Date
    
    enum CodingKeys: String, CodingKey {
        case user
        case readAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decode(String.self, forKey: .user)
        
        let formatter = ISO8601DateFormatter()
        if let readAtString = try container.decodeIfPresent(String.self, forKey: .readAt) {
            readAt = formatter.date(from: readAtString) ?? Date()
        } else {
            readAt = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(user, forKey: .user)
        
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: readAt), forKey: .readAt)
    }
}

struct SendMessageRequest: Codable {
    let content: String
    let messageType: String = "text"
}

struct MessagesResponse: Codable {
    let messages: [Message]
}

struct MessageResponse: Codable {
    let message: Message
}
