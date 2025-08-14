//
//  AuthView.swift
//  CollabNotes
//
//  Created by prajwal sanap on 08/08/25.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @FocusState private var focusedField: AuthField?
    
    enum AuthField {
        case email, password, name, confirmPassword
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Form
                    formSection
                    
                    // Submit Button
                    submitButton
                    
                    // Toggle Mode
                    toggleModeButton
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        errorSection(errorMessage)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(Color(.systemGroupedBackground))
            .onTapGesture {
                hideKeyboard()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("CollabNotes")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(viewModel.isLoginMode ? "Welcome back!" : "Create your account")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 32)
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 16) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .email)
                    .onSubmit {
                        if viewModel.isLoginMode {
                            focusedField = .password
                        } else {
                            focusedField = .name
                        }
                    }
                
                if let error = viewModel.emailError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Name Field (Register only)
            if !viewModel.isLoginMode {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Full Name", text: $viewModel.name)
                        .textFieldStyle(CustomTextFieldStyle())
                        .focused($focusedField, equals: .name)
                        .onSubmit {
                            focusedField = .password
                        }
                    
                    if let error = viewModel.nameError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(CustomTextFieldStyle())
                    .focused($focusedField, equals: .password)
                    .onSubmit {
                        if viewModel.isLoginMode {
                            if viewModel.canSubmit {
                                viewModel.login()
                            }
                        } else {
                            focusedField = .confirmPassword
                        }
                    }
                
                if let error = viewModel.passwordError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Confirm Password Field (Register only)
            if !viewModel.isLoginMode {
                VStack(alignment: .leading, spacing: 8) {
                    SecureField("Confirm Password", text: $viewModel.confirmPassword)
                        .textFieldStyle(CustomTextFieldStyle())
                        .focused($focusedField, equals: .confirmPassword)
                        .onSubmit {
                            if viewModel.canSubmit {
                                viewModel.register()
                            }
                        }
                    
                    if let error = viewModel.confirmPasswordError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    // MARK: - Submit Button
    
    private var submitButton: some View {
        Button(action: {
            hideKeyboard()
            if viewModel.isLoginMode {
                viewModel.login()
            } else {
                viewModel.register()
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(viewModel.submitButtonText)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(viewModel.canSubmit ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canSubmit)
        .padding(.top, 8)
    }
    
    // MARK: - Toggle Mode Button
    
    private var toggleModeButton: some View {
        Button(action: {
            viewModel.toggleMode()
            focusedField = nil
        }) {
            Text(viewModel.toggleModeText)
                .font(.subheadline)
                .foregroundColor(.blue)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Error Section
    
    private func errorSection(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .padding(.top, 8)
    }
}

// MARK: - Custom Text Field Style

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview {
    AuthView()
}
