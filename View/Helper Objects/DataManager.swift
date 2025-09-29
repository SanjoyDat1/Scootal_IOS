//
//  DataMangager.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2024-12-17.
//
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseCore

class DataManager: ObservableObject {
    @Published var scooters: [Scooter] = []
    @Published var currentUserBooking: Booking? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    init() {
        fetchScooters()
        fetchCurrentUserBooking()
    }
    
    func fetchScooters() {
        scooters.removeAll()
        isLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        let ref = db.collection("Scooters")
        
        ref.getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error fetching scooters: \(error.localizedDescription)"
                    return
                }
                
                guard let snapshot = snapshot else {
                    self.errorMessage = "Unexpected error: No data found."
                    return
                }
                
                self.scooters = snapshot.documents.compactMap { document in
                    let data = document.data()
                    let id = data["id"] as? String ?? document.documentID
                    let description = data["description"] as? String ?? ""
                    let imageURL = data["imageURL"] as? String ?? ""
                    let isAvailable = data["isAvailable"] as? Bool ?? false
                    let isBooked = data["isBooked"] as? Bool ?? false
                    let activeBooking = data["activeBooking"] as? Bool ?? false
                    let isFeatured = data["isFeatured"] as? Bool ?? false
                    let confirmationCode = data["confirmationCode"] as? String ?? ""
                    let location = data["location"] as? String ?? ""
                    let totalPricePerHour = data["totalPricePerHour"] as? Double ?? 0.0
                    let allow6HourRentals = data["allow6HourRentals"] as? Bool ?? false
                    let allow24HourRentals = data["allow24HourRentals"] as? Bool ?? false
                    let userPricePerHour = data["userPricePerHour"] as? Double ?? 0.0
                    let eympaFeePerHour = data["eympaFeePerHour"] as? Double ?? 0.0
                    let sixHourPrice = data["sixHourPrice"] as? Double ?? 0.0
                    let fullDayPrice = data["fullDayPrice"] as? Double ?? 0.0
                    let isElectric = data["isElectric"] as? Bool ?? false
                    let range = data["range"] as? Int ?? 0
                    let brand = data["brand"] as? String ?? ""
                    let modelName = data["modelName"] as? String ?? ""
                    let yearOfMake = data["yearOfMake"] as? String ?? ""
                    let damages = data["damages"] as? String ?? ""
                    let restrictions = data["restrictions"] as? String ?? ""
                    let specialNotes = data["specialNotes"] as? String ?? ""
                    let scooterName = data["scooterName"] as? String ?? ""
                    let topSpeed = data["topSpeed"] as? Int ?? 0
                    let ownerID = data["ownerID"] as? String ?? ""
                    let isConfirmed = data["isConfirmed"] as? Bool ?? false
                    let unavailableAt = data["unavailableAt"] as? Timestamp ?? Timestamp()
                    
                    // Parse availability data
                    var availability: [String: Scooter.DailyAvailability] = [:]
                    if let availabilityData = data["availability"] as? [String: [String: Any]] {
                        for (day, dayData) in availabilityData {
                            if let isAvailable = dayData["isAvailable"] as? Bool,
                               let startTime = dayData["startTime"] as? String,
                               let endTime = dayData["endTime"] as? String {
                                availability[day] = Scooter.DailyAvailability(isAvailable: isAvailable, startTime: startTime, endTime: endTime)
                            }
                        }
                    }
                                                            
                    return Scooter(id: id,
                                   description: description,
                                   imageURL: imageURL,
                                   isAvailable: isAvailable,
                                   isBooked: isBooked,
                                   activeBooking: activeBooking,
                                   isFeatured: isFeatured,
                                   confirmationCode: confirmationCode,
                                   location: location,
                                   totalPricePerHour: totalPricePerHour,
                                   allow6HourRentals: allow6HourRentals,
                                   allow24HourRentals: allow24HourRentals,
                                   eympaFeePerHour: eympaFeePerHour,
                                   userPricePerHour: userPricePerHour,
                                   sixHourPrice: sixHourPrice,
                                   fullDayPrice: fullDayPrice,
                                   isElectric: isElectric,
                                   range: range,
                                   brand: brand,
                                   modelName: modelName,
                                   yearOfMake: yearOfMake,
                                   damages: damages,
                                   restrictions: restrictions,
                                   specialNotes: specialNotes,
                                   scooterName: scooterName,
                                   topSpeed: topSpeed,
                                   ownerID: ownerID,
                                   isConfirmed: isConfirmed,
                                   unavailableAt: unavailableAt,
                                   availability: availability)
                }
            }
        }
    }
    
    func toggleAvailability(scooterId: String, availableSet: Bool) {
        let db = Firestore.firestore()
        let scooterRef = db.collection("Scooters").document(scooterId)
        
        scooterRef.updateData([
            "isAvailable": availableSet,
        ]) { error in
            if let error = error {
                print("Error updating availability: \(error.localizedDescription)")
            } else {
                print("Availability updated successfully.")
            }
        }
    }
    
    func fetchCurrentUserBooking() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("Users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user data: \(error)")
                return
            }
            
            if let data = snapshot?.data(), let isBooking = data["isBooking"] as? Bool, isBooking {
                if let bookingID = data["currentBookingID"] as? String {
                    self.fetchBookingDetails(bookingID: bookingID)
                }
            }
        }
    }
    
    func fetchBookingDetails(bookingID: String) {
        let db = Firestore.firestore()
        db.collection("Bookings").document(bookingID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching booking details: \(error)")
                return
            }
            
            if let data = snapshot?.data() {
                self.currentUserBooking = Booking(data: data)
            }
        }
    }
}
