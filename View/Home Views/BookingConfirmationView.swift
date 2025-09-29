

import SwiftUI
import FirebaseFirestore
import FirebaseCore

struct Booking: Identifiable, Decodable {
    @DocumentID var id: String?

    var confirmationCode: String?
    var customerId: String?
    var ownerId: String?
    var scooterID: String?
    var endTime: Timestamp?
    var isAccepted: Bool?
    var isRejected: Bool?
    var isActive: Bool?
    var location: String?
    var fullDayPrice: String?
    var sixHourPrice: String?
    var estimatedPrice: String?
    var safetySentence: String?
    var topSpeed: Int?
    var scooterName: String?
    
    

    init(data: [String: Any]) {
        self.id = data["id"] as? String ?? UUID().uuidString
        self.confirmationCode = data["confirmationCode"] as? String ?? ""
        self.customerId = data["customerId"] as? String ?? ""
        self.ownerId = data["ownerId"] as? String ?? ""
        self.scooterID = data["scooterID"] as? String ?? ""
        self.safetySentence = data["safetySentence"] as? String ?? "Safety first!"
        self.scooterName = data["scooterName"] as? String ?? ""
        self.location = data["location"] as? String ?? "Unknown Location"
        self.endTime = data["endTime"] as? Timestamp ?? Timestamp()
        self.estimatedPrice = data["estimatedPrice"] as? String ?? "$0.00"
        self.fullDayPrice = data["fullDayPrice"] as? String ?? "$0.00"
        self.sixHourPrice = data["sixHourPrice"] as? String ?? "$0.00"
        self.topSpeed = data["topSpeed"] as? Int ?? 0
        self.isAccepted = data["isAccepted"] as? Bool ?? false
        self.isActive = data["isActive"] as? Bool ?? false
        self.isRejected = data["isRejected"] as? Bool ?? false
    }
}

struct BookingConfirmationView: View {
    @State private var booking: Booking?
    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var customerFirstName: String? = ""
    @State private var customerLastName: String? = ""
    @State private var customerEmail: String? = ""

    @State private var scooterName: String? = ""
    @State private var scooterSerialNumber: String? = ""
    @State private var estimatedValue: String? = ""

    @State private var showUserProfile = false

    var bookingId: String

    let db = Firestore.firestore()

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(UIColor(hex: "primary")), Color(UIColor(hex: "primary")).opacity(0.05)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                    Text("Scootal")
                        .font(.system(size: 50, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                
                if isLoading {
                    ProgressView("Loading Booking...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        .padding()
                } else if let booking = booking {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Booking Confirmation")
                                .font(.system(size: 24, weight: .bold))
                                .padding(.bottom, 5)
                                .foregroundColor(Color(UIColor(hex: "primary")))

                            DetailSection(title: "Scooter Details") {
                                DetailRow(title: "Name", value: scooterName ?? "N/A")
                                DetailRow(title: "Top Speed", value: "\(booking.topSpeed ?? 0) mph")
                                DetailRow(title: "Serial Number", value: scooterSerialNumber ?? "N/A")
                                DetailRow(title: "Estimated Value", value: "$\(estimatedValue ?? "N/A")")
                            }

                            DetailSection(title: "Customer Details") {
                                DetailRow(title: "Name", value: "\(customerFirstName ?? "N/A") \(customerLastName ?? "N/A")")
                                DetailRow(title: "Email", value: customerEmail ?? "N/A")
                            }

                            DetailSection(title: "Booking Details") {
                                DetailRow(title: "Location", value: booking.location ?? "N/A")
                                DetailRow(title: "Estimated Price", value: booking.estimatedPrice ?? "N/A", valueColor: .green)
                                DetailRow(title: "End Time", value: formatEndTime(booking.endTime))
                                Text("Safety Notice: \(booking.safetySentence ?? "No safety message")")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                    .padding(.top, 5)
                            }

                            Divider().padding(.vertical, 10)

                            HStack(spacing: 20) {
                                ActionButton(title: "Confirm", color: .green) {
                                    confirmBooking(ownerId: booking.ownerId ?? "")
                                }
                                ActionButton(title: "Deny", color: .red) {
                                    denyBooking(scooterID: booking.scooterID ?? "")
                                }
                            }
                            .padding(.top, 10)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color(UIColor(hex: "secondary")).opacity(0.1), radius: 5, x: 0, y: 5)
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.title3)
                        .padding()
                }
            }
            .padding(.top, 25)
        }
        .onAppear {
            fetchBookingData()
        }
        .fullScreenCover(isPresented: $showUserProfile) {
            UserProfileView()
        }
    }

    struct DetailSection<Content: View>: View {
        let title: String
        let content: Content

        init(title: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(UIColor(hex: "secondary")))
                content
            }
        }
    }

    struct DetailRow: View {
        let title: String
        let value: String
        var valueColor: Color = Color(UIColor(hex: "secondary"))

        var body: some View {
            HStack {
                Text("\(title):")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(UIColor(hex: "secondary")))
                Spacer()
                Text(value)
                    .foregroundColor(Color(UIColor(hex: "secondary")))
                    .font(.system(size: 16))
            }
            .padding(.horizontal)
        }
    }

    struct ActionButton: View {
        let title: String
        let color: Color
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(color)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .shadow(color: Color(UIColor(hex: "secondary")).opacity(0.2), radius: 5, x: 0, y: 5)
            }
        }
    }
    
    func formatEndTime(_ timestamp: Timestamp?) -> String {
            guard let timestamp = timestamp else { return "N/A" }
            let date = timestamp.dateValue()
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    
    func fetchBookingData() {
        db.collection("Bookings").document(bookingId).getDocument { (document, error) in
            if let error = error {
                self.errorMessage = "Error fetching booking: \(error.localizedDescription)"
                self.isLoading = false
            } else if let document = document, document.exists {
                do {
                    self.booking = try document.data(as: Booking.self)
                    
                    // Check if the scooterID and customerId exist in the booking object
                    guard let scooterID = self.booking?.scooterID, !scooterID.isEmpty else {
                        self.errorMessage = "Scooter ID is missing."
                        self.isLoading = false
                        return
                    }
                    guard let customerId = self.booking?.customerId, !customerId.isEmpty else {
                        self.errorMessage = "Customer ID is missing."
                        self.isLoading = false
                        return
                    }
                    
                    self.fetchScooterInformation() // Fetch scooter information only after scooterID is valid
                    self.fetchCustomerInformation() // Fetch customer information only after customerId is valid
                } catch {
                    self.errorMessage = "Error decoding booking data: \(error.localizedDescription)"
                }
                self.isLoading = false
            } else {
                self.errorMessage = "No such booking."
                self.isLoading = false
            }
        }
    }

    
    func confirmBooking(ownerId: String) {
        guard var updatedBooking = booking else { return }
        updatedBooking.isAccepted = true
        updatedBooking.isActive = true
        updatedBooking.isRejected = false
        
        db.collection("Bookings").document(bookingId).setData([
            "isAccepted": updatedBooking.isAccepted ?? true,
            "isActive": updatedBooking.isActive ?? true,
            "isRejected": updatedBooking.isRejected ?? false
        ], merge: true) { error in
            if let error = error {
                print("Error confirming booking: \(error.localizedDescription)")
            } else {
                print("Booking confirmed!")
            }
        }
        db.collection("Users").document(ownerId).setData([
            "isBooking": true,
        ], merge: true) { error in
            if let error = error {
                print("Error confirming booking: \(error.localizedDescription)")
            } else {
                print("Booking confirmed!")
            }
        }
        showUserProfile = true
        
        db.collection("Scooters").document(booking?.scooterID ?? "").setData([
            "isBooked": false,
            "activeBooking": true,
        ], merge: true) { error in
            if let error = error {
                print("Error confirming booking: \(error.localizedDescription)")
            } else {
                print("Booking confirmed!")
            }
        }
    }
    
    func denyBooking(scooterID: String) {
        guard var updatedBooking = booking else { return }
        updatedBooking.isAccepted = false
        updatedBooking.isActive = false
        updatedBooking.isRejected = true
        
        db.collection("Bookings").document(bookingId).setData([
            "isAccepted": updatedBooking.isAccepted,
            "isActive": updatedBooking.isActive,
            "isRejected": updatedBooking.isRejected
        ], merge: true) { error in
            if let error = error {
                print("Error denying booking: \(error.localizedDescription)")
            } else {
                print("Booking denied!")
            }
            showUserProfile = true
        }
        
        db.collection("Scooters").document(scooterID).setData([
            "isBooked": false,
            "isAvailable": false,
        ], merge: true) { error in
            if let error = error {
                print("Error confirming booking: \(error.localizedDescription)")
            } else {
                print("Booking confirmed!")
            }
        }
    }
    
    func fetchCustomerInformation() {
        // Ensure that `booking` is not nil and has a valid customerId before proceeding
        guard let customerId = booking?.customerId else {
            self.errorMessage = "Customer ID is missing."
            self.isLoading = false
            return
        }

        db.collection("Users").document(customerId).getDocument { (document, error) in
            if let error = error {
                self.errorMessage = "Error fetching user data: \(error.localizedDescription)"
                self.isLoading = false
            } else if let document = document, document.exists {
                // Extract firstName, lastName, and email
                if let data = document.data() {
                    if let firstName = data["firstName"] as? String,
                       let lastName = data["lastName"] as? String,
                       let email = data["emailID"] as? String {
                        // Assign these values to the booking object or user object
                        self.customerFirstName = firstName
                        self.customerLastName = lastName
                        self.customerEmail = email
                    } else {
                        self.errorMessage = "Missing data: firstName, lastName, or email."
                    }
                }
                self.isLoading = false
            } else {
                self.errorMessage = "No such user."
                self.isLoading = false
            }
        }
    }
    
    func fetchScooterInformation() {
        guard let scooterID = booking?.scooterID else {
            self.errorMessage = "Scooter ID is missing."
            self.isLoading = false
            return
        }
        
        db.collection("Scooters").document(scooterID).getDocument { (document, error) in
            if let error = error {
                self.errorMessage = "Error fetching scooter data: \(error.localizedDescription)"
                self.isLoading = false
            } else if let document = document, document.exists {
                // Extract scooterName and serialNumber
                if let data = document.data() {
                    print("Scooter Data: \(data)") // Debug print
                    if let scooterName = data["scooterName"] as? String,
                       let serialNumber = data["serialNumber"] as? String,
                       let estimatedValue = data["estimatedValue"] as? String{
                        // Assign these values to the scooterName and serialNumber
                        self.scooterName = scooterName
                        self.estimatedValue = estimatedValue
                        self.scooterSerialNumber = serialNumber
                        print("Scooter Name: \(scooterName)") // Debug print
                    } else {
                        self.errorMessage = "Missing scooter data: scooterName or serialNumber."
                    }
                }
                self.isLoading = false
            } else {
                self.errorMessage = "No such scooter."
                self.isLoading = false
            }
        }
    }

}

struct BookingConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        BookingConfirmationView(bookingId: "0761EE94-7304-4C65-A3A5-C3B1B0F9C9E7")
            .previewLayout(.sizeThatFits) // Previews with proper layout
            .padding()
    }
}
