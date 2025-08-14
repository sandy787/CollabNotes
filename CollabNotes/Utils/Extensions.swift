//
//  Extensions.swift
//  CollabNotes
//
//  Created by prajwal sanap on 08/08/25.
//

import Foundation
import SwiftUI

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    func chatTimeDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: self)
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: self)
        }
    }
    
    func messageTimeDisplay() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

extension String {
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
    
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension Color {
    static let chatBackground = Color(.systemGroupedBackground)
    static let messageReceived = Color(.systemGray5)
    static let messageSent = Color.blue
    static let onlineGreen = Color.green
    static let offlineGray = Color.gray
}

// MARK: - Custom ViewModifiers

struct MessageBubble: ViewModifier {
    let isFromCurrentUser: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isFromCurrentUser ? Color.messageSent : Color.messageReceived)
            .foregroundColor(isFromCurrentUser ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func messageBubbleStyle(isFromCurrentUser: Bool) -> some View {
        modifier(MessageBubble(isFromCurrentUser: isFromCurrentUser))
    }
}
