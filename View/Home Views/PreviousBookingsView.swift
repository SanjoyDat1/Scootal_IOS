//
//  PreviousBookingsView.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-01-26.
//
import SwiftUI
import FirebaseFirestore
import FirebaseCore

struct PreviousBookingsView: View {
    let userId: String
    
    @State private var bookings: [Booking] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(UIColor(hex: "primary"))))
                } else if let errorMessage = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    bookingList
                }
            }
            .navigationTitle("Past Trips")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(UIColor(hex: "primary")))
                    }
                }
            }
        }
        .onAppear(perform: fetchUserBookings)
    }
    
    private var bookingList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if bookings.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "scooter")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No trips yet")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                        Text("Your past trips will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                } else {
                    ForEach(bookings) { booking in
                        BookingCard(booking: booking)
                            .transition(.opacity)
                    }
                }
            }
            .padding()
        }
    }
    
    private func fetchUserBookings() {
        isLoading = true
        let userBookingsRef = db.collection("Users").document(userId)
        
        userBookingsRef.getDocument { document, error in
            if let error = error {
                errorMessage = "Failed to load trips: \(error.localizedDescription)"
                isLoading = false
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let bookingIds = data["bookings"] as? [String] else {
                bookings = []
                isLoading = false
                return
            }
            
            fetchBookingDetails(bookingIds: bookingIds)
        }
    }
    
    private func fetchBookingDetails(bookingIds: [String]) {
        let group = DispatchGroup()
        var fetchedBookings: [Booking] = []
        
        for bookingId in bookingIds {
            group.enter()
            db.collection("Bookings").document(bookingId).getDocument { document, error in
                defer { group.leave() }
                
                if let document = document, document.exists,
                   let data = document.data() {
                    let booking = Booking(data: data)
                    fetchedBookings.append(booking)
                }
            }
        }
        
        group.notify(queue: .main) {
            bookings = fetchedBookings.sorted { ($0.endTime?.dateValue() ?? Date()) > ($1.endTime?.dateValue() ?? Date()) }
            isLoading = false
        }
    }
}

struct BookingCard: View {
    let booking: Booking
    @State private var showingReceipt = false
    @State private var showingReport = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.scooterName ?? "Scooter Ride")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(formatDate(booking.endTime))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(booking.estimatedPrice ?? "$0.00")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(UIColor(hex: "primary")))
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            
            Divider()
            
            HStack(spacing: 12) {
                Button(action: { showingReceipt = true }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Receipt")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                
                Button(action: { showingReport = true }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text("Report")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingReceipt) {
            ReceiptDetailView(booking: booking)
        }
        .sheet(isPresented: $showingReport) {
            ReportIssueView(booking: booking)
        }
    }
    
    private func formatDate(_ timestamp: Timestamp?) -> String {
        guard let date = timestamp?.dateValue() else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ReceiptDetailView: View {
    let booking: Booking
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(booking.scooterName ?? "Scooter Ride")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(formatDate(booking.endTime))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        DetailRow(label: "Pickup", value: booking.location ?? "N/A")
                        DetailRow(label: "Drop-off", value: booking.location ?? "N/A")
                        DetailRow(label: "Six-Hour Rate", value: booking.sixHourPrice ?? "N/A")
                        DetailRow(label: "Full-Day Rate", value: booking.fullDayPrice ?? "N/A")
                        DetailRow(label: "Total", value: booking.estimatedPrice ?? "$0.00", isBold: true)
                        DetailRow(label: "Confirmation", value: booking.confirmationCode ?? "N/A")
                        DetailRow(label: "Scooter ID", value: booking.scooterID ?? "N/A")
                        DetailRow(label: "Top Speed", value: "\(booking.topSpeed ?? 0) mph")
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Receipt")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    
    private func formatDate(_ timestamp: Timestamp?) -> String {
        guard let date = timestamp?.dateValue() else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ReportIssueView: View {
    let booking: Booking
    @State private var issueType: String = "General"
    @State private var description: String = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @Environment(\.dismiss) private var dismiss
    
    private let db = Firestore.firestore()
    private let issueTypes = ["General", "Payment", "Scooter Issue", "Safety", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Issue Details")) {
                    Picker("Issue Type", selection: $issueType) {
                        ForEach(issueTypes, id: \.self) { type in
                            Text(type)
                        }
                    }
                    
                    TextEditor(text: $description)
                        .frame(height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.2)))
                }
                
                Section {
                    Button(action: submitIssue) {
                        Text(isSubmitting ? "Submitting..." : "Submit Report")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(isSubmitting || description.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Report Issue")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Report Submitted", isPresented: $showSuccess) {
                Button("OK") { dismiss() }
            } message: {
                Text("We've received your report and will review it soon.")
            }
        }
    }
    
    private func submitIssue() {
        isSubmitting = true
        let issueData: [String: Any] = [
            "bookingId": booking.id ?? "N/A",
            "customerId": booking.customerId ?? "N/A",
            "scooterId": booking.scooterID ?? "N/A",
            "issueType": issueType,
            "description": description,
            "timestamp": FieldValue.serverTimestamp(),
            "status": "pending"
        ]
        
        db.collection("ReportedIssues").addDocument(data: issueData) { error in
            DispatchQueue.main.async {
                isSubmitting = false
                if let error = error {
                    print("Error submitting issue: \(error.localizedDescription)")
                } else {
                    showSuccess = true
                }
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var isBold: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(isBold ? .semibold : .regular)
        }
    }
}


struct PreviousBookingsView_Previews: PreviewProvider {
    static var previews: some View {
        PreviousBookingsView(userId: "8yRpWfqr41QVHiQSojSIyGddn6N2")
    }
}
