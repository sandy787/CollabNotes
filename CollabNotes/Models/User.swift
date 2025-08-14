//
//  User.swift
//  CollabNotes
//
//  Created by prajwal sanap on 08/08/25.
//

import Foundation

struct User: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let email: String
    let name: String
    let avatar: String?
    let isOnline: Bool
    let lastSeen: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email
        case name
        case avatar
        case isOnline
        case lastSeen
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        isOnline = try container.decodeIfPresent(Bool.self, forKey: .isOnline) ?? false
        
        if let lastSeenString = try container.decodeIfPresent(String.self, forKey: .lastSeen) {
            let formatter = ISO8601DateFormatter()
            lastSeen = formatter.date(from: lastSeenString) ?? Date()
        } else {
            lastSeen = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(avatar, forKey: .avatar)
        try container.encode(isOnline, forKey: .isOnline)
        
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: lastSeen), forKey: .lastSeen)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    init(id: String, email: String, name: String, avatar: String? = nil, isOnline: Bool = false, lastSeen: Date = Date()) {
        self.id = id
        self.email = email
        self.name = name
        self.avatar = avatar
        self.isOnline = isOnline
        self.lastSeen = lastSeen
    }
}

struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}
