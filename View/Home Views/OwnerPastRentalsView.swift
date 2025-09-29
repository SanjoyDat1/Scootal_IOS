//
//  OwnerPastRentalsView.swift
//  Scootal
//
//  Created by Sanjoy Datta on 2025-03-30.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct OwnerPastRentalsView: View {
    let ownerId: String
    
    @State private var rentals: [Booking] = []
    @State private var totalEarnings: Double = 0.0
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingDetails = false
    @State private var selectedRental: Booking?
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
                    errorView(message: errorMessage)
                } else {
                    rentalsList
                }
            }
            .navigationTitle("Your Scooter Earnings")
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
        .onAppear(perform: fetchRentals)
        .sheet(isPresented: $showingDetails) {
            if let rental = selectedRental {
                RentalDetailView(rental: rental)
            }
        }
    }
    
    private var rentalsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                earningsHeader
                
                if rentals.isEmpty {
                    emptyStateView
                } else {
                    ForEach(rentals) { rental in
                        RentalCard(rental: rental, onDetailsTapped: {
                            selectedRental = rental
                            showingDetails = true
                        })
                            .transition(.opacity)
                    }
                }
            }
            .padding()
        }
    }
    
    private var earningsHeader: some View {
        VStack(spacing: 8) {
            Text("Total Earnings (After Fees)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(String(format: "$%.2f", totalEarnings))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor(hex: "primary")))
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "scooter")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No rentals yet")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            Text("Rentals of your scooters will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 50)
    }
    
    private func errorView(message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            Button("Retry") {
                fetchRentals()
            }
            .frame(width: 120)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
    
    private func fetchRentals() {
        isLoading = true
        rentals = []
        totalEarnings = 0.0
        
        db.collection("Bookings")
            .whereField("ownerId", isEqualTo: ownerId)
            .whereField("isActive", isEqualTo: false) // Only past rentals
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Failed to load rentals: \(error.localizedDescription)"
                    isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    rentals = []
                    isLoading = false
                    return
                }
                
                rentals = documents.compactMap { doc in
                    let data = doc.data()
                    return Booking(data: data)
                }.sorted { ($0.endTime?.dateValue() ?? Date()) > ($1.endTime?.dateValue() ?? Date()) }
                
                // Calculate total earnings after fees
                totalEarnings = rentals.reduce(0) { total, rental in
                    let basePrice = Double(rental.estimatedPrice?.replacingOccurrences(of: "$", with: "") ?? "0.00") ?? 0.0
                    let fees = basePrice * 0.20 + 1.0 // 20% fees + $1 unlock fee
                    let netEarnings = max(0, basePrice - fees)
                    return total + netEarnings
                }
                
                isLoading = false
            }
    }
}

struct RentalCard: View {
    let rental: Booking
    let onDetailsTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(rental.scooterName ?? "Scooter")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(formatDate(rental.endTime))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(calculateNetEarnings(rental: rental))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(UIColor(hex: "primary")))
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            
            Divider()
            
            HStack(spacing: 12) {
                DetailButton(label: "Details", icon: "info.circle", color: .blue) {
                    onDetailsTapped()
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ timestamp: Timestamp?) -> String {
        guard let date = timestamp?.dateValue() else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func calculateNetEarnings(rental: Booking) -> String {
        let basePrice = Double(rental.estimatedPrice?.replacingOccurrences(of: "$", with: "") ?? "0.00") ?? 0.0
        let fees = basePrice * 0.20 + 1.0 // 20% fees + $1 unlock fee
        let netEarnings = max(0, basePrice - fees)
        return String(format: "$%.2f", netEarnings)
    }
}

struct RentalDetailView: View {
    let rental: Booking
    @State private var renter: Renter?
    @State private var scooter: Scooter?
    @State private var isLoadingDetails = true
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                if isLoadingDetails {
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
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Header Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text(rental.scooterName ?? "Scooter Rental")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text(formatDate(rental.endTime))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(calculateNetEarnings(rental: rental))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(UIColor(hex: "primary")))
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            
                            // Renter Information Section
                            SectionHeader(title: "Renter Information", icon: "person.fill")
                            if let renter = renter {
                                NewInfoCard {
                                    DetailRow(label: "Name", value: "\(renter.firstName) \(renter.lastName)")
                                    DetailRow(label: "Email", value: renter.email)
                                    DetailRow(label: "Phone", value: renter.phoneNumber)
                                }
                            } else {
                                NewInfoCard {
                                    DetailRow(label: "Name", value: "N/A")
                                    DetailRow(label: "Email", value: "N/A")
                                    DetailRow(label: "Phone", value: "N/A")
                                }
                            }
                            
                            // Scooter Information Section
                            SectionHeader(title: "Scooter Details", icon: "scooter")
                            if let scooter = scooter {
                                NewInfoCard {
                                    DetailRow(label: "Name", value: scooter.scooterName)
                                    DetailRow(label: "Brand", value: scooter.brand)
                                    DetailRow(label: "Model", value: scooter.modelName)
                                    DetailRow(label: "Year", value: "\(scooter.yearOfMake)")
                                    DetailRow(label: "Top Speed", value: "\(scooter.topSpeed) mph")
                                    DetailRow(label: "Range", value: "\(scooter.range) miles")
                                    DetailRow(label: "Electric", value: scooter.isElectric ? "Yes" : "No")
                                    DetailRow(label: "Damages", value: scooter.damages.isEmpty ? "None" : scooter.damages)
                                    DetailRow(label: "Restrictions", value: scooter.restrictions.isEmpty ? "None" : scooter.restrictions)
                                    DetailRow(label: "Special Notes", value: scooter.specialNotes.isEmpty ? "None" : scooter.specialNotes)
                                }
                            } else {
                                NewInfoCard {
                                    DetailRow(label: "Name", value: "N/A")
                                    DetailRow(label: "Brand", value: "N/A")
                                    DetailRow(label: "Model", value: "N/A")
                                    DetailRow(label: "Year", value: "N/A")
                                    DetailRow(label: "Top Speed", value: "N/A")
                                    DetailRow(label: "Range", value: "N/A")
                                    DetailRow(label: "Electric", value: "N/A")
                                    DetailRow(label: "Damages", value: "N/A")
                                    DetailRow(label: "Restrictions", value: "N/A")
                                    DetailRow(label: "Special Notes", value: "N/A")
                                }
                            }
                            
                            // Rental Information Section
                            SectionHeader(title: "Rental Information", icon: "calendar")
                            NewInfoCard {
                                DetailRow(label: "Location", value: rental.location ?? "N/A")
                                DetailRow(label: "Six-Hour Rate", value: rental.sixHourPrice ?? "N/A")
                                DetailRow(label: "Full-Day Rate", value: rental.fullDayPrice ?? "N/A")
                                DetailRow(label: "Confirmation Code", value: rental.confirmationCode ?? "N/A")
                                DetailRow(label: "Safety Note", value: rental.safetySentence ?? "N/A")
                            }
                            
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Rental Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                fetchRenterAndScooterDetails()
            }
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    
    private func fetchRenterAndScooterDetails() {
        isLoadingDetails = true
        errorMessage = nil
        
        let dispatchGroup = DispatchGroup()
        
        // Fetch renter details
        if let customerId = rental.customerId {
            dispatchGroup.enter()
            db.collection("Users").document(customerId).getDocument { document, error in
                if let error = error {
                    self.errorMessage = "Failed to load renter details: \(error.localizedDescription)"
                } else if let document = document, document.exists, let data = document.data() {
                    self.renter = Renter(data: data)
                }
                dispatchGroup.leave()
            }
        }
        
        // Fetch scooter details using the provided Scooter struct
        if let scooterId = rental.scooterID {
            dispatchGroup.enter()
            db.collection("Scooters").document(scooterId).getDocument { document, error in
                if let error = error {
                    self.errorMessage = "Failed to load scooter details: \(error.localizedDescription)"
                } else if let document = document, document.exists, let data = document.data() {
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
                    
                    self.scooter = Scooter(
                        id: id,
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
                        availability: availability
                    )
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.isLoadingDetails = false
        }
    }
    
    private func formatDate(_ timestamp: Timestamp?) -> String {
        guard let date = timestamp?.dateValue() else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func calculateNetEarnings(rental: Booking) -> String {
        let basePrice = Double(rental.estimatedPrice?.replacingOccurrences(of: "$", with: "") ?? "0.00") ?? 0.0
        let fees = basePrice * 0.20 + 1.0 // 20% fees + $1 unlock fee
        let netEarnings = max(0, basePrice - fees)
        return String(format: "$%.2f", netEarnings)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color(UIColor(hex: "primary")))
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct NewInfoCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct Renter: Identifiable {
    let id: String?
    let firstName: String
    let lastName: String
    let email: String
    let phoneNumber: String
    
    init(data: [String: Any]) {
        self.id = data["id"] as? String
        self.firstName = data["firstName"] as? String ?? "Unknown"
        self.lastName = data["lastName"] as? String ?? "Renter"
        self.email = data["schoolEmail"] as? String ?? "N/A"
        self.phoneNumber = data["phoneNumber"] as? String ?? "N/A"
    }
}

struct DetailButton: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(label)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(8)
        }
    }
}

struct OwnerPastRentals_Previews: PreviewProvider {
    static var previews: some View {
        OwnerPastRentalsView(ownerId: Auth.auth().currentUser?.uid ?? "")
    }
}

