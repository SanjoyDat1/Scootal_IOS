//
//  ConfirmBookingView.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-01-04.
//

import SwiftUI
import FirebaseFirestore

struct ConfirmBookingView: View {
    let scooterID: String
    @StateObject private var viewModel = BookingViewModel()
    @State private var hasConfirmed: Bool = false
    @State private var hasCancelled: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else if let scooter = viewModel.scooter {
                // Header
                Text("Confirm Booking")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                    .padding(.top)
                
                // Scooter Details
                VStack(alignment: .leading, spacing: 10) {
                    Text("🚲 Scooter Name:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(scooter.scooterName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text("💲 Price per Hour:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("$\(String(format: "%.2f", scooter.totalPricePerHour))")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text("📍 Location:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(scooter.location)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text("🛵 Description:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(scooter.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                // Confirm or Cancel Buttons
                HStack {
                    Button(action: {
                        confirmBooking(scooterID: scooter.id)
                    }) {
                        Text("Confirm Booking")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(scooter.isBooked)
                    
                    Button(action: {
                        cancelBooking(scooterID: scooter.id)
                    }) {
                        Text("Cancel Booking")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            } else {
                Text(viewModel.errorMessage ?? "Error fetching scooter data.")
                    .foregroundColor(.red)
                    .padding()
            }
            
            Spacer()
        }
        .onAppear {
            viewModel.fetchScooterDetails(scooterID: scooterID)
        }
    }

    // Function to confirm the booking
    func confirmBooking(scooterID: String) {
        guard let scooter = viewModel.scooter else { return }
        
        // Update the scooter in Firestore
        Firestore.firestore().collection("scooters").document(scooterID).updateData([
            "isBooked": true,
            "confirmationCode": UUID().uuidString.prefix(6).uppercased()
        ]) { error in
            if let error = error {
                print("Error confirming booking: \(error)")
            } else {
                hasConfirmed = true
            }
        }
    }
    
    // Function to cancel the booking
    func cancelBooking(scooterID: String) {
        guard let scooter = viewModel.scooter else { return }
        
        // Update the scooter in Firestore
        Firestore.firestore().collection("scooters").document(scooterID).updateData([
            "isBooked": false,
            "confirmationCode": ""
        ]) { error in
            if let error = error {
                print("Error canceling booking: \(error)")
            } else {
                hasCancelled = true
            }
        }
    }
}
