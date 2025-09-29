//
//  ReturnScooterView.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-01-17.

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ReturnSheet: View {
    let bookingId: String  //The booking ID passed fromt the parent view
    let scooterId: String // The scooter ID passed from the parent view
    @State private var confirmationCode: String = "123456" // Mock confirmation code
    @State private var isOwnerEnteredCode: Bool = false    // Track whether the owner has entered the code
    @State private var isCodeVisible: Bool = false        // For toggling code visibility
    @State private var showScooterListView: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("Return Scooter")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor(hex: "primary")))
                .padding(.top, 35)

            Text("Confirmation Code")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color(UIColor(hex: "primary")))

            // Confirmation code display with toggle visibility option
            HStack {
                Text(isCodeVisible ? confirmationCode : "••••••")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(UIColor(hex: "accent")))
                    .padding(.vertical)
                
                Button(action: {
                    isCodeVisible.toggle()
                }) {
                    Image(systemName: isCodeVisible ? "eye.slash" : "eye")
                        .foregroundColor(Color(UIColor(hex: "primary")))
                        .padding(.trailing)
                }
            }

            // Text indicating that the owner must input the code
            Text("Give the owner this code.")
                .font(.body)
                .foregroundColor(.gray)
                .padding(.bottom)

            // Button for confirming code entry
            Button(action: {
                // Simulate refreshing the screen by setting the flag to true
                returnScooter(bookingId: bookingId, scooterId: scooterId)
                isOwnerEnteredCode.toggle()
                showScooterListView = true
            }) {
                Text(isOwnerEnteredCode ? "Booking Ended" : "Confirm Code Entry")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isOwnerEnteredCode ? Color.green : Color(UIColor(hex: "primary")))
                    .cornerRadius(12)
                    .shadow(radius: 10)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .onChange(of: isOwnerEnteredCode) { _ in
            // Logic for ending the booking (could be a navigation, alert, etc.)
            if isOwnerEnteredCode {
                // In real-world use, perform your "end ride" action here, like notifying the server.
                print("Ride ended successfully!")
            }
        }
        .fullScreenCover(isPresented: $showScooterListView) {
            ScooterListView()
        }
    }
    
    func returnScooter(bookingId: String, scooterId: String) {
        let db = Firestore.firestore()
        
        db.collection("Bookings").document(bookingId).setData([
            "isAccepted": true,
            "isActive": false,
            "isRejected": false
        ], merge: true) { error in
            if let error = error {
                print("Error denying booking: \(error.localizedDescription)")
            } else {
                print("Booking denied!")
            }        }
        
        db.collection("Scooters").document(scooterId).setData([
            "isBooked": false,
            "activeBooking": false,
            "available": false
        ], merge: true) { error in
            if let error = error {
                print("Error setting scooter details: \(error.localizedDescription)")
            } else {
                print("Scooter details confirmed!")
            }
        }
    }
}
