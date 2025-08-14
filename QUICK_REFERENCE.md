# 🚀 Quick Reference - Backend API

## 🌐 Production URLs
- **API**: `https://server-production-b292.up.railway.app`
- **WebSocket**: `wss://server-production-b292.up.railway.app`

## 🔑 Authentication
```bash
# Register
POST /api/auth/register
{"email": "user@example.com", "password": "password123", "name": "User Name"}

# Login  
POST /api/auth/login
{"email": "user@example.com", "password": "password123"}

# Headers for authenticated requests
Authorization: Bearer JWT_TOKEN
```

## 💬 Core Chat APIs
```bash
# Get chats
GET /api/chats

# Create chat
POST /api/chats
{"participantIds": ["USER_ID"], "isGroup": false}

# Get messages
GET /api/messages/CHAT_ID

# Send message
POST /api/messages/CHAT_ID
{"content": "Hello world!"}

# Get note
GET /api/notes/CHAT_ID

# Update note
PUT /api/notes/CHAT_ID
{"content": "Note content", "version": 1}
```

## ⚡ Socket.io Events
```javascript
// Connect with auth
const socket = io(API_URL, { auth: { token: JWT_TOKEN } });

// Client emits
socket.emit('join-chats', [chatId]);
socket.emit('send-message', {chatId, content});
socket.emit('typing-message', {chatId, isTyping});
socket.emit('update-note', {chatId, content, version});

// Server emits
socket.on('new-message', (data) => {...});
socket.on('user-online', (data) => {...});
socket.on('user-typing-message', (data) => {...});
socket.on('note-updated', (data) => {...});
```

## 📱 SwiftUI Dependencies
```swift
// Package.swift
.package(url: "https://github.com/socketio/socket.io-client-swift", from: "16.0.0")
.package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2")
```

## ✅ Status: Backend 100% Complete & Deployed!
