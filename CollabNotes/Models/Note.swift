//
//  Note.swift
//  CollabNotes
//
//  Created by prajwal sanap on 08/08/25.
//

import Foundation

struct Note: Codable, Identifiable, Equatable {
    let id: String
    let chatId: String
    let content: String
    let lastEditedBy: User?
    let version: Int
    let collaborators: [Collaborator]
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case chatId
        case content
        case lastEditedBy
        case version
        case collaborators
        case createdAt
        case updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        chatId = try container.decode(String.self, forKey: .chatId)
        content = try container.decode(String.self, forKey: .content)
        lastEditedBy = try container.decodeIfPresent(User.self, forKey: .lastEditedBy)
        version = try container.decode(Int.self, forKey: .version)
        collaborators = try container.decode([Collaborator].self, forKey: .collaborators)
        
        let formatter = ISO8601DateFormatter()
        
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
        try container.encode(chatId, forKey: .chatId)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(lastEditedBy, forKey: .lastEditedBy)
        try container.encode(version, forKey: .version)
        try container.encode(collaborators, forKey: .collaborators)
        
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(formatter.string(from: updatedAt), forKey: .updatedAt)
    }
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Collaborator: Codable, Identifiable, Equatable {
    let id: String
    let user: User
    let permissions: [String]
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case permissions
        case joinedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        user = try container.decode(User.self, forKey: .user)
        permissions = try container.decode([String].self, forKey: .permissions)
        
        let formatter = ISO8601DateFormatter()
        if let joinedAtString = try container.decodeIfPresent(String.self, forKey: .joinedAt) {
            joinedAt = formatter.date(from: joinedAtString) ?? Date()
        } else {
            joinedAt = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(user, forKey: .user)
        try container.encode(permissions, forKey: .permissions)
        
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: joinedAt), forKey: .joinedAt)
    }
    
    static func == (lhs: Collaborator, rhs: Collaborator) -> Bool {
        return lhs.id == rhs.id
    }
}

struct UpdateNoteRequest: Codable {
    let content: String
    let version: Int
}

struct NoteResponse: Codable {
    let note: Note
}
