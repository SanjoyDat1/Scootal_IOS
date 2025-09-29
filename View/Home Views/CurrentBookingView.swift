//
//  CurrentBookingView.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-01-04.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CurrentBookingView: View {
    let userId: String
    @State private var booking: Booking? = nil
    @State private var showHelpView: Bool = false
    @State private var showReturnSheet: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var selectedTab: BookingTab = .scooterDetails
    
    var body: some View {
        ZStack {
            Color(UIColor(hex: "primary")).opacity(0.9)
            .ignoresSafeArea()

            VStack {
                Text("Scootal")
                    .font(.system(size: 50, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
            
                HeaderView()

                if isLoading {
                    LoadingView()
                } else if let booking = booking {
                    TabView(selection: $selectedTab) {
                        ScooterDetailsView(booking: booking)
                            .tag(BookingTab.scooterDetails)
                        BookingDetailsView(booking: booking)
                            .tag(BookingTab.bookingDetails)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    
                } else if let errorMessage = errorMessage {
                    ErrorView(errorMessage: errorMessage)
                }

                HStack {
                    HelpButton(showHelpView: $showHelpView)
                    Spacer()
                    ReturnScooterButton(showReturnSheet: $showReturnSheet)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 15)
            }
        }
        .sheet(isPresented: $showHelpView) {
            HelpAndSupportScreen()
        }
        .sheet(isPresented: $showReturnSheet) {
            ReturnSheet(bookingId: booking?.id ?? "", scooterId: booking?.scooterID ?? "")
                .presentationDetents([.height(350)])
        }
        .onAppear {
            fetchBooking(for: userId)
        }
    }

    private func fetchBooking(for userId: String) {
        let db = Firestore.firestore()
        isLoading = true

        db.collection("Bookings")
            .whereField("ownerId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Error fetching booking: \(error.localizedDescription)"
                    isLoading = false
                    return
                }

                guard let documents = snapshot?.documents, let firstDoc = documents.first else {
                    errorMessage = "No booking found for this user."
                    isLoading = false
                    return
                }

                do {
                    booking = try firstDoc.data(as: Booking.self)
                    errorMessage = nil
                } catch {
                    errorMessage = "Error parsing booking data: \(error.localizedDescription)"
                }

                isLoading = false
            }
    }
}

enum BookingTab {
    case scooterDetails
    case bookingDetails
}

struct HeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Booking")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(.white))
                .padding(.bottom, 5)
            
            Text("Thanks for booking a scooter through Scootal.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            VStack(alignment: .leading, spacing: 10) {
                Label("Ride with a helmet.", systemImage: "figure.walk.circle")
                Label("Lock the scooter when not in use.", systemImage: "lock.circle")
                Label("Ride below speed limits.", systemImage: "speedometer")
                Label("Stay safe!", systemImage: "heart.circle")
            }
            .font(.body)
            .foregroundColor(.white.opacity(0.85))
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(10)
        }
        .padding()
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.9)]), startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(15)
        .padding(.top, 5)
        .shadow(color: Color(UIColor(hex: "secondary")).opacity(0.3), radius: 10, x: 0, y: 5)
    }
}


struct ScooterDetailsView: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Scooter Information")
                .fontWeight(.bold)
                .font(.title)
                .foregroundColor(Color(.white))
                .padding(.bottom, 15)
                .frame(maxWidth: .infinity, alignment: .center)

            DetailRowView(label: "Name", value: booking.scooterName ?? "N/A")
            DetailRowView(label: "Top Speed", value: "\(booking.topSpeed ?? 0) mph")
            DetailRowView(label: "Confirmation Code", value: booking.confirmationCode ?? "N/A")
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.9)]), startPoint: .top, endPoint: .bottom)))
        .padding([.leading, .trailing])
    }
}

struct BookingDetailsView: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Booking Details")
                .fontWeight(.bold)
                .font(.title)
                .foregroundColor(Color(.white))
                .padding(.bottom, 15)
                .frame(maxWidth: .infinity, alignment: .center)
            
            DetailRowView(label: "Location", value: booking.location ?? "N/A")
            DetailRowView(label: "Estimated Price", value: booking.estimatedPrice ?? "N/A")
            DetailRowView(label: "Safety Notice", value: booking.safetySentence ?? "No safety message", italic: true)
            DetailRowView(label: "End Time", value: formattedDate(booking.endTime))
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 15).fill(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.9)]), startPoint: .top, endPoint: .bottom)))
        .padding([.leading, .trailing])
    }

    private func formattedDate(_ timestamp: Timestamp?) -> String {
        guard let timestamp = timestamp else { return "N/A" }
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRowView: View {
    let label: String
    let value: String
    var valueColor: Color = Color(.white)
    var italic: Bool = false

    var body: some View {
        HStack {
            Text("\(label):")
                .fontWeight(.bold)
                .foregroundColor(Color(.white))
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .italic(italic)
        }
    }
}

struct ErrorView: View {
    let errorMessage: String

    var body: some View {
        VStack {
            Text("Error")
                .font(.headline)
                .foregroundColor(.white)
            Text(errorMessage)
                .font(.body)
                .foregroundColor(Color(.white))
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView("Loading Booking...")
                .progressViewStyle(CircularProgressViewStyle(tint: Color(UIColor(hex: "primary"))))
                .padding()
            Text("Please wait while we fetch your booking details.")
                .font(.caption)
                .foregroundColor(Color(.white))
                .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HelpButton: View {
    @Binding var showHelpView: Bool

    var body: some View {
        Button(action: {
            showHelpView = true
        }) {
            HStack {
                Image(systemName: "questionmark.circle")
                    .foregroundColor(Color(.white))
                Text("Help")
                    .foregroundColor(Color(.white))
            }
            .padding()
            .frame(minWidth: 150) // Set a minimum width for the button
            .background(Capsule().fill(Color.red))
            .shadow(radius: 5)
        }
    }
}

struct ReturnScooterButton: View {
    @Binding var showReturnSheet: Bool
    var body: some View {
        Button(action: {
            showReturnSheet = true
            returnScooter()// Wrap returnScooter in a closure
        }) {
            HStack {
                Image(systemName: "arrow.uturn.left.circle")
                    .foregroundColor(Color(.white))
                Text("Return")
                    .foregroundColor(Color(.white))
            }
            .padding()
            .frame(minWidth: 150) // Set a minimum width for the button
            .background(Capsule().fill(Color.green))
            .shadow(radius: 5)
        }
    }
    
    func returnScooter() {
        let userId = Auth.auth().currentUser?.uid ?? ""
        let db = Firestore.firestore()
        db.collection("Users").document(userId).setData([
            "isBooking": false,
        ], merge: true) { error in
            if let error = error {
                print("Error confirming booking: \(error.localizedDescription)")
            } else {
                print("Booking confirmed!")
            }
        }
    }
}

// Preview
struct CurrentBookingView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentBookingView(userId: "8yRpWfqr41QVHiQSojSIyGddn6N2")
    }
}
