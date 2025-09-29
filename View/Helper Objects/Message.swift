//
//  Messages.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2024-12-26.
//

import Foundation

struct Message: Identifiable {
    let id: String
    let content: String
    let senderId: String
    let isRead: Bool
    let timestamp: Date

    var isFromCurrentUser: Bool {
        senderId == Auth.auth().currentUser?.uid
    }
    
    var timestampFormatted: String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: timestamp)
        }
}
