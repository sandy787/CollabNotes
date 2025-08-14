//
//  NoteView.swift
//  CollabNotes
//
//  Created by prajwal sanap on 08/08/25.
//

import SwiftUI

struct NoteView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: NoteViewModel
    @FocusState private var isEditorFocused: Bool
    
    init(chatId: String) {
        _viewModel = StateObject(wrappedValue: NoteViewModel(chatId: chatId))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Info
                headerView
                
                // Note Editor
                editorView
                
                // Status Bar
                statusBar
            }
            .navigationTitle("Shared Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.saveNote()
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .onDisappear {
                viewModel.stopTyping()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            // Collaborators Info
            if !viewModel.collaboratorNames.isEmpty {
                HStack {
                    Image(systemName: "person.2.circle")
                        .foregroundColor(.blue)
                    
                    Text("Collaborators: \(viewModel.collaboratorNames)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            // Last Edited Info
            if !viewModel.lastEditedInfo.isEmpty {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.lastEditedInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            // Typing Indicator
            if !viewModel.typingText.isEmpty {
                HStack {
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 4, height: 4)
                                .scaleEffect(1.0)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(Double(index) * 0.2),
                                    value: true
                                )
                        }
                    }
                    
                    Text(viewModel.typingText)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
            }
            
            Divider()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Editor View
    
    private var editorView: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else {
                noteEditor
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading note...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noteEditor: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Editor
            TextEditor(text: $viewModel.noteContent)
                .focused($isEditorFocused)
                .font(.body)
                .padding()
                .background(Color(.systemBackground))
                .onChange(of: viewModel.noteContent) { _ in
                    viewModel.startTyping()
                }
                .overlay(
                    // Placeholder when empty
                    Group {
                        if viewModel.noteContent.isEmpty {
                            VStack {
                                HStack {
                                    Text("Start typing your shared note...")
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                        .padding(.top)
                                    Spacer()
                                }
                                Spacer()
                            }
                        }
                    }
                )
        }
    }
    
    // MARK: - Status Bar
    
    private var statusBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                // Save Status
                HStack(spacing: 4) {
                    if viewModel.isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if !viewModel.saveStatusText.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    
                    Text(viewModel.saveStatusText.isEmpty ? "Auto-save enabled" : viewModel.saveStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Word count
                if !viewModel.noteContent.isEmpty {
                    Text("\(wordCount) words")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Computed Properties
    
    private var wordCount: Int {
        let words = viewModel.noteContent.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
}

// MARK: - Preview

#Preview {
    NoteView(chatId: "sample-chat-id")
}
