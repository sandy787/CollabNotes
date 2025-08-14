//
//  Chat.swift
//  CollabNotes
//  Created by prajwal sanap on 08/08/25.
//  Chat.swift
//  CollabNotes
//  Created by prajwal sanap on 08/08/25.

import Foundation

struct Chat: Codable, Identifiable, Equatable {
    let id: String
    let name: String?
    let participants: [User]
    let isGroup: Bool
    let lastMessage: Message?
    let lastActivity: Date
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case participants
        case isGroup
        case lastMessage
        case lastActivity
        case createdAt
        case updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        participants = try container.decode([User].self, forKey: .participants)
        isGroup = try container.decode(Bool.self, forKey: .isGroup)
        lastMessage = try container.decodeIfPresent(Message.self, forKey: .lastMessage)
        
        let formatter = ISO8601DateFormatter()
        
        if let lastActivityString = try container.decodeIfPresent(String.self, forKey: .lastActivity) {
            lastActivity = formatter.date(from: lastActivityString) ?? Date()
        } else {
            lastActivity = Date()
        }
        
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = formatter.date(from: createdAtString) ?? Date()
        } else {
            createdAt = Date()
        }
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = formatter.date(from: updatedAtString) ?? Date()
        } else {
            updatedAt = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(participants, forKey: .participants)
        try container.encode(isGroup, forKey: .isGroup)
        try container.encodeIfPresent(lastMessage, forKey: .lastMessage)
        
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: lastActivity), forKey: .lastActivity)
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(formatter.string(from: updatedAt), forKey: .updatedAt)
    }
    
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(id: String, name: String? = nil, participants: [User], isGroup: Bool, lastMessage: Message? = nil, lastActivity: Date = Date(), createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.participants = participants
        self.isGroup = isGroup
        self.lastMessage = lastMessage
        self.lastActivity = lastActivity
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var displayName: String {
        if let name = name {
            return name
        }
        
        if !isGroup && participants.count == 2 {
            return participants.first?.name ?? "Unknown"
        }
        
        return "Group Chat"
    }
}

struct CreateChatRequest: Codable {
    let participantIds: [String]
    let isGroup: Bool
    let name: String?
}

struct ChatsResponse: Codable {
    let chats: [Chat]
}
