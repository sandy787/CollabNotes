//  CollabNotesApp.swift
//  CollabNotes
//  Created by prajwal sanap on 08/08/25.

import SwiftUI

@main
struct CollabNotesApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var socketService = SocketService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(socketService)
                .onAppear {
                    authService.checkAuthenticationStatus()
                }
        }
    }
}
