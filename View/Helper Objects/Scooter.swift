//
//  Scooter.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2024-12-17.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct Scooter: Identifiable, Codable {
    var id: String
    var description: String
    var imageURL: String
    var isAvailable: Bool
    var isBooked: Bool
    var activeBooking: Bool
    var isFeatured: Bool
    var confirmationCode: String
    var location: String
    var totalPricePerHour: Double
    var allow6HourRentals: Bool
    var allow24HourRentals: Bool
    var eympaFeePerHour: Double
    var userPricePerHour: Double
    var sixHourPrice: Double
    var fullDayPrice: Double
    var isElectric: Bool
    var range: Int
    var brand: String
    var modelName: String
    var yearOfMake: String
    var damages: String
    var restrictions: String
    var specialNotes: String
    var scooterName: String
    var topSpeed: Int
    var ownerID: String
    var isConfirmed: Bool
    var unavailableAt: Timestamp
    var availability: [String: DailyAvailability]
    
    struct DailyAvailability: Codable {
        var isAvailable: Bool
        var startTime: String
        var endTime: String
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "scooterName": scooterName,
            "location": location,
            "totalPricePerHour": totalPricePerHour,
            "allow6HourRentals": allow6HourRentals,
            "allow24HourRentals": allow6HourRentals,
            "ownerID": ownerID,
            "imageURL": imageURL,
            "isAvailable": isAvailable,
            "description": description,
            "isBooked": isBooked,
            "activeBooking": activeBooking,
            "isFeatured": isFeatured,
            "confirmationCode": confirmationCode,
            "eympaFeePerHour": eympaFeePerHour,
            "userPricePerHour": userPricePerHour,
            "sixHourPrice": sixHourPrice,
            "fullDayPrice": fullDayPrice,
            "isElectric": isElectric,
            "range": range,
            "brand": brand,
            "modelName": modelName,
            "yearOfMake": yearOfMake,
            "damages": damages,
            "restrictions": restrictions,
            "specialNotes": specialNotes,
            "topSpeed": topSpeed,
            "isConfirmed": isConfirmed,
            "unavailableAt": unavailableAt
        ]
        
        let availabilityDict: [String: DailyAvailability] = [:]

        dict["availability"] = availabilityDict
        
        return dict
    }
    
}
