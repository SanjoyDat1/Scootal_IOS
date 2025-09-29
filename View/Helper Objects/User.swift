//
//  User.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2024-12-19.
//

import SwiftUI
import FirebaseFirestore

struct User: Identifiable, Codable {
    var id: String
    let uid: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let email: String
    let schoolEmail: String
    let profileImageURL: String
    let isEmailVerified: Bool
    let isBooking: Bool
    let currentBookingID: String?
    let bookings: [String]
    let fcmToken: String?
    let createdAt: Timestamp?
    
    init(data: [String: Any]) {
        self.id = data["id"] as? String ?? ""
        self.uid = data["uid"] as? String ?? ""
        self.firstName = data["firstName"] as? String ?? ""
        self.lastName = data["lastName"] as? String ?? ""
        self.phoneNumber = data["phoneNumber"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.schoolEmail = data["schoolEmail"] as? String ?? ""
        self.profileImageURL = data["profileImageURL"] as? String ?? ""
        self.isEmailVerified = data["isEmailVerified"] as? Bool ?? false
        self.isBooking = data["isBooking"] as? Bool ?? false
        self.currentBookingID = data["currentBookingID"] as? String
        self.bookings = data["bookings"] as? [String] ?? []
        self.fcmToken = data["fcmToken"] as? String
        self.createdAt = data["createdAt"] as? Timestamp
    }
}
 
