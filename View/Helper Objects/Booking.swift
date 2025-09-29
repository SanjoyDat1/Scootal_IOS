//
//  Booking.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-01-04.
//

import Foundation
import FirebaseFirestore

struct Booking: Identifiable, Codable {
    let id: String
    let scooterID: String
    let location: String?
    let topSpeed: Int?
    let scooterName: String?
    let isAccepted: Bool
    let isActive: Bool
    let isRejected: Bool
    let endTime: Timestamp?
    let estimatedPrice: String?
    let sixHourPrice: String?
    let fullDayPrice: String?
    let customerId: String
    let ownerId: String
    let confirmationCode: String?
    let unlockFee: String?
    let feesAndTaxes: String?
    let safetySentence: String?
    let startTime: Timestamp?
    let createdAt: Timestamp?
    
    init(data: [String: Any]) {
        self.id = data["id"] as? String ?? ""
        self.scooterID = data["scooterID"] as? String ?? ""
        self.location = data["location"] as? String
        self.topSpeed = data["topSpeed"] as? Int
        self.scooterName = data["scooterName"] as? String
        self.isAccepted = data["isAccepted"] as? Bool ?? false
        self.isActive = data["isActive"] as? Bool ?? false
        self.isRejected = data["isRejected"] as? Bool ?? false
        self.endTime = data["endTime"] as? Timestamp
        self.estimatedPrice = data["estimatedPrice"] as? String
        self.sixHourPrice = data["sixHourPrice"] as? String
        self.fullDayPrice = data["fullDayPrice"] as? String
        self.customerId = data["customerId"] as? String ?? ""
        self.ownerId = data["ownerId"] as? String ?? ""
        self.confirmationCode = data["confirmationCode"] as? String
        self.unlockFee = data["unlockFee"] as? String
        self.feesAndTaxes = data["feesAndTaxes"] as? String
        self.safetySentence = data["safetySentence"] as? String
        self.startTime = data["startTime"] as? Timestamp
        self.createdAt = data["createdAt"] as? Timestamp
    }
    
    init(id: String, scooterID: String, location: String?, topSpeed: Int?, scooterName: String?, isAccepted: Bool, isActive: Bool, isRejected: Bool, endTime: Timestamp?, estimatedPrice: String?, sixHourPrice: String?, fullDayPrice: String?, customerId: String, ownerId: String, confirmationCode: String?, unlockFee: String?, feesAndTaxes: String?, safetySentence: String?, startTime: Timestamp?, createdAt: Timestamp?) {
        self.id = id
        self.scooterID = scooterID
        self.location = location
        self.topSpeed = topSpeed
        self.scooterName = scooterName
        self.isAccepted = isAccepted
        self.isActive = isActive
        self.isRejected = isRejected
        self.endTime = endTime
        self.estimatedPrice = estimatedPrice
        self.sixHourPrice = sixHourPrice
        self.fullDayPrice = fullDayPrice
        self.customerId = customerId
        self.ownerId = ownerId
        self.confirmationCode = confirmationCode
        self.unlockFee = unlockFee
        self.feesAndTaxes = feesAndTaxes
        self.safetySentence = safetySentence
        self.startTime = startTime
        self.createdAt = createdAt
    }
}
