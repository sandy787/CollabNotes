//
//  ContentView.swift
//  CollabNotes
//
//  Created by prajwal sanap on 08/08/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var socketService: SocketService
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                ChatListView()
                    .onAppear {
                        // Connect to socket when user is authenticated
                        socketService.connect()
                    }
                    .onDisappear {
                        // Disconnect when leaving the app
                        socketService.disconnect()
                    }
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
        .environmentObject(SocketService.shared)
}
