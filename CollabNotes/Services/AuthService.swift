//
//  AuthService.swift
//  CollabNotes
//
//  Created by prajwal sanap on 08/08/25.
//

import Foundation
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    private let apiService = APIService.shared
    private let keychainService = KeychainService.shared
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Status
    
    func checkAuthenticationStatus() {
        if let token = keychainService.getJWTToken(), !token.isEmpty {
            Task {
                await getCurrentUser()
            }
        } else {
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.currentUser = nil
            }
        }
    }
    
    // MARK: - Register
    
    @MainActor
    func register(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = RegisterRequest(email: email, password: password, name: name)
            let requestData = try apiService.encode(request)
            
            let response: AuthResponse = try await apiService.request(
                endpoint: APIConfig.Endpoints.register,
                method: .POST,
                body: requestData,
                requiresAuth: false
            )
            
            // Save token and user info
            _ = keychainService.saveJWTToken(response.token)
            _ = keychainService.saveUserID(response.user.id)
            
            currentUser = response.user
            isAuthenticated = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Login
    
    @MainActor
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = LoginRequest(email: email, password: password)
            let requestData = try apiService.encode(request)
            
            let response: AuthResponse = try await apiService.request(
                endpoint: APIConfig.Endpoints.login,
                method: .POST,
                body: requestData,
                requiresAuth: false
            )
            
            // Save token and user info
            _ = keychainService.saveJWTToken(response.token)
            _ = keychainService.saveUserID(response.user.id)
            
            currentUser = response.user
            isAuthenticated = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Get Current User
    
    @MainActor
    func getCurrentUser() async {
        do {
            let user: User = try await apiService.request(
                endpoint: APIConfig.Endpoints.me,
                method: .GET
            )
            
            currentUser = user
            isAuthenticated = true
            
            // Update stored user ID if needed
            _ = keychainService.saveUserID(user.id)
            
        } catch {
            // If we can't get current user, clear auth
            logout()
        }
    }
    
    // MARK: - Logout
    
    @MainActor
    func logout() {
        keychainService.clearAll()
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }
    
    // MARK: - Validation Methods
    
    func validateEmail(_ email: String) -> String? {
        if email.trimmed.isEmpty {
            return "Email is required"
        }
        if !email.trimmed.isValidEmail() {
            return "Please enter a valid email address"
        }
        return nil
    }
    
    func validatePassword(_ password: String) -> String? {
        if password.isEmpty {
            return "Password is required"
        }
        if password.count < 6 {
            return "Password must be at least 6 characters"
        }
        return nil
    }
    
    func validateName(_ name: String) -> String? {
        if name.trimmed.isEmpty {
            return "Name is required"
        }
        if name.trimmed.count < 2 {
            return "Name must be at least 2 characters"
        }
        return nil
    }
    
    // MARK: - Helper Methods
    
    func clearError() {
        errorMessage = nil
    }
}
