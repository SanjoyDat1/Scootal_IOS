//
//  BookingViewModel.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-01-04.
//

import FirebaseFirestore
import SwiftUI

class BookingViewModel: ObservableObject {
    @Published var scooter: Scooter?
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    
    private var db = Firestore.firestore()
    
    // Function to fetch scooter details from Firestore
    func fetchScooterDetails(scooterID: String) {
        db.collection("Scooters").document(scooterID).getDocument { [weak self] snapshot, error in
            if let error = error {
                self?.errorMessage = "Failed to fetch scooter: \(error.localizedDescription)"
                self?.isLoading = false
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                do {
                    // Decode the scooter data into the Scooter model
                    let scooter = try snapshot.data(as: Scooter.self)
                    self?.scooter = scooter
                } catch {
                    self?.errorMessage = "Failed to decode scooter data."
                }
            }
            self?.isLoading = false
        }
    }
}
