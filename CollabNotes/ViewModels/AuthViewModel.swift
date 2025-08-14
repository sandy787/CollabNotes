//  AuthViewModel.swift
//  CollabNotes
//  Created by prajwal sanap on 08/08/25.

import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var confirmPassword = ""
    
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var nameError: String?
    @Published var confirmPasswordError: String?
    
    @Published var isLoginMode = true
    
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    var isLoading: Bool {
        authService.isLoading
    }
    
    var errorMessage: String? {
        authService.errorMessage
    }
    
    var isAuthenticated: Bool {
        authService.isAuthenticated
    }
    
    init() {
        $email
            .sink { [weak self] _ in
                self?.emailError = nil
                self?.authService.clearError()
            }
            .store(in: &cancellables)
        
        $password
            .sink { [weak self] _ in
                self?.passwordError = nil
                self?.authService.clearError()
            }
            .store(in: &cancellables)
        
        $name
            .sink { [weak self] _ in
                self?.nameError = nil
                self?.authService.clearError()
            }
            .store(in: &cancellables)
        
        $confirmPassword
            .sink { [weak self] _ in
                self?.confirmPasswordError = nil
                self?.authService.clearError()
            }
            .store(in: &cancellables)
    }
    
    
    func toggleMode() {
        isLoginMode.toggle()
        clearErrors()
        clearFields()
    }
    
    func login() {
        guard validateLoginForm() else { return }
        
        Task {
            await authService.login(email: email.trimmed, password: password)
        }
    }
    
    func register() {
        guard validateRegisterForm() else { return }
        
        Task {
            await authService.register(
                email: email.trimmed,
                password: password,
                name: name.trimmed
            )
        }
    }
    
        func logout() {
        Task { @MainActor in
            authService.logout()
            clearFields()
            clearErrors()
        }
    }
    
    
    private func validateLoginForm() -> Bool {
        var isValid = true
        
        if let error = authService.validateEmail(email) {
            emailError = error
            isValid = false
        }
        
        if let error = authService.validatePassword(password) {
            passwordError = error
            isValid = false
        }
        
        return isValid
    }
    
    private func validateRegisterForm() -> Bool {
        var isValid = true
        
        if let error = authService.validateEmail(email) {
            emailError = error
            isValid = false
        }
        
        if let error = authService.validatePassword(password) {
            passwordError = error
            isValid = false
        }
        
        if let error = authService.validateName(name) {
            nameError = error
            isValid = false
        }
        
        if password != confirmPassword {
            confirmPasswordError = "Passwords do not match"
            isValid = false
        }
        
        return isValid
    }
    
    
    private func clearFields() {
        email = ""
        password = ""
        name = ""
        confirmPassword = ""
    }
    
    private func clearErrors() {
        emailError = nil
        passwordError = nil
        nameError = nil
        confirmPasswordError = nil
        authService.clearError()
    }
    
    
    var canSubmit: Bool {
        if isLoginMode {
            return !email.trimmed.isEmpty && !password.isEmpty && !isLoading
        } else {
            return !email.trimmed.isEmpty && 
                   !password.isEmpty && 
                   !name.trimmed.isEmpty && 
                   !confirmPassword.isEmpty && 
                   !isLoading
        }
    }
    
    var submitButtonText: String {
        if isLoading {
            return isLoginMode ? "Signing In..." : "Creating Account..."
        } else {
            return isLoginMode ? "Sign In" : "Create Account"
        }
    }
    
    var toggleModeText: String {
        isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Sign In"
    }
}
