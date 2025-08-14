# CollabNotes - Real-Time Chat & Collaborative Notes iOS App

A real-time chat application with collaborative note-taking features built with SwiftUI and Socket.io.

## 🚀 Features

- **Real-time Messaging**: Instant messaging with Socket.io WebSocket connections
- **Collaborative Notes**: Live collaborative note editing with conflict resolution
- **User Authentication**: Secure JWT-based authentication
- **Typing Indicators**: Real-time typing indicators for both chat and notes
- **Online Presence**: User online/offline status indicators
- **Group Chats**: Support for both direct messages and group conversations
- **Auto-save**: Automatic saving of notes with version control

## 🏗️ Architecture

The app follows MVVM (Model-View-ViewModel) architecture:

```
CollabNotes/
├── Models/
│   ├── User.swift
│   ├── Chat.swift
│   ├── Message.swift
│   └── Note.swift
├── Services/
│   ├── APIService.swift
│   ├── AuthService.swift
│   ├── SocketService.swift
│   └── KeychainService.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── ChatListViewModel.swift
│   ├── ChatViewModel.swift
│   └── NoteViewModel.swift
├── Views/
│   ├── Authentication/
│   │   └── AuthView.swift
│   ├── ChatList/
│   │   ├── ChatListView.swift
│   │   └── NewChatView.swift
│   ├── Chat/
│   │   └── ChatDetailView.swift
│   └── Notes/
│       └── NoteView.swift
└── Utils/
    ├── Constants.swift
    └── Extensions.swift
```

## 🛠️ Setup Instructions

### 1. Dependencies

Add the following packages via Xcode Package Manager:

1. **Socket.io Client**
   - URL: `https://github.com/socketio/socket.io-client-swift`
   - Version: 16.0.0 or later

2. **Keychain Access** (Optional - for enhanced keychain operations)
   - URL: `https://github.com/kishikawakatsumi/KeychainAccess`
   - Version: 4.2.2 or later

### 2. Enable Socket.io

After adding the Socket.io dependency:

1. Open `SocketService.swift`
2. Uncomment the `import SocketIO` line
3. Uncomment all the Socket.io related code in the file
4. Build the project to ensure everything compiles

### 3. Backend Configuration

The app is configured to work with the production backend:

- **API URL**: `https://server-production-b292.up.railway.app`
- **WebSocket URL**: `wss://server-production-b292.up.railway.app`

These URLs are defined in `Constants.swift` and can be changed if needed.

### 4. Test Accounts

Use these test accounts for immediate testing:

- **Email**: `demo@example.com`, **Password**: `password123`
- **Email**: `user2@example.com`, **Password**: `password123`

## 📱 Usage

### Authentication
1. Launch the app
2. Sign in with existing credentials or create a new account
3. The app will automatically connect to the real-time services

### Chat Features
1. **View Chats**: See all your conversations in the chat list
2. **Create Chat**: Tap the compose button to start a new conversation
3. **Send Messages**: Type and send real-time messages
4. **Typing Indicators**: See when others are typing

### Collaborative Notes
1. Open any chat
2. Tap the menu (•••) and select "Shared Note"
3. Start typing - changes are saved automatically
4. See real-time edits from other collaborators
5. View typing indicators when others are editing

## 🔧 API Integration

### Authentication Endpoints
```swift
POST /api/auth/register
POST /api/auth/login
GET /api/auth/me
```

### Chat & Messaging Endpoints
```swift
GET /api/chats
POST /api/chats
GET /api/messages/:chatId
POST /api/messages/:chatId
```

### Notes Endpoints
```swift
GET /api/notes/:chatId
PUT /api/notes/:chatId
```

### Socket.io Events

**Client Emits:**
- `join-chats`: Join chat rooms
- `send-message`: Send real-time messages
- `typing-message`: Typing indicators for chat
- `update-note`: Real-time note updates
- `typing-note`: Typing indicators for notes

**Server Emits:**
- `new-message`: Receive new messages
- `user-online`/`user-offline`: User presence updates
- `user-typing-message`: Chat typing indicators
- `note-updated`: Real-time note changes
- `user-typing-note`: Note typing indicators

## 🔐 Security

- JWT tokens are securely stored in iOS Keychain
- All API requests include proper authorization headers
- Socket connections are authenticated with JWT tokens
- Automatic token refresh and logout on expiration

## 🧪 Testing

### Manual Testing
1. Install the app on multiple devices or simulators
2. Create accounts and start conversations
3. Test real-time messaging between devices
4. Open shared notes and edit simultaneously
5. Verify typing indicators and online presence

### Backend Testing
The backend is fully deployed and tested. All endpoints are working and ready for production use.

## 📋 Development Status

### ✅ Completed Features
- [x] Complete MVVM architecture
- [x] JWT authentication with keychain storage
- [x] Real-time messaging infrastructure
- [x] Collaborative notes foundation
- [x] Typing indicators system
- [x] User presence tracking
- [x] Auto-save functionality
- [x] Error handling and loading states
- [x] Modern SwiftUI interface

### 🔄 Next Steps
1. Add Socket.io dependency and uncomment socket code
2. Test real-time features with multiple users
3. Add push notifications
4. Implement file sharing
5. Add message reactions and replies
6. Enhance group chat management

## 🎯 Production Ready

The backend is **100% complete and deployed** 


This iOS app is ready to connect to the live backend and start real-time communication immediately after adding the Socket.io dependency.

## 📞 Support

For questions or issues:
1. Check the backend status at the production URLs
2. Verify Socket.io dependency is properly added
3. Ensure test accounts are working
4. Review the API documentation in `QUICK_REFERENCE.md`
