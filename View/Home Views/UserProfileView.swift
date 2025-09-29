//
//  UserProfileView.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2024-12-25.
//
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseCore
import FirebaseStorage
import PassKit
import iPhoneNumberField

struct UserProfileView: View {
    @StateObject private var dataManager = DataManager()
    @Environment(\.presentationMode) var presentationMode
    @State private var user: User?
    @State private var personalID: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var identification: String = ""
    @State private var isEditing: Bool = false
    @State private var showEditProfileAlert: Bool = false
    @State private var errorMessage: String?
    @State private var showingAddScooterView = false
    @State private var isLoading = true
    @State private var userScooters: [Scooter] = []
    @State private var showScooterListView = false
    @State private var showBookingView = false
    @State private var showScooterPickupView = false
    @State private var faceImageURL: URL?
    @State private var isBookingInProgress = false
    @State private var scooterToConfirm: Scooter?
    @State private var confirmationCode = ""
    @State private var showSignOutAlert = false
    @State private var showContentView = false
    @State private var showPrevRentalsView = false

    private func fetchUserScooters() {
        let db = Firestore.firestore()
        guard let currentUser = Auth.auth().currentUser else {
            print("Error: No current user logged in")
            return
        }

        let ref = db.collection("Scooters").whereField("ownerID", isEqualTo: currentUser.uid)
        ref.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching scooters: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            DispatchQueue.main.async {
                self.userScooters = snapshot?.documents.compactMap { document in
                    let data = document.data()
                    return self.createScooter(from: data, documentID: document.documentID)
                } ?? []
                self.isLoading = false
            }
        }
    }

    private func createScooter(from data: [String: Any], documentID: String) -> Scooter {
        let id = data["id"] as? String ?? documentID
        let confirmationCode = data["confirmationCode"] as? String ?? ""
        let description = data["description"] as? String ?? ""
        let imageURL = data["imageURL"] as? String ?? ""
        let isAvailable = data["isAvailable"] as? Bool ?? false
        let isBooked = data["isBooked"] as? Bool ?? false
        let activeBooking = data["activeBooking"] as? Bool ?? false
        let isFeatured = data["isFeatured"] as? Bool ?? false
        let location = data["location"] as? String ?? ""
        let totalPricePerHour = data["totalPricePerHour"] as? Double ?? 0.0
        let allow6HourRentals = data["allow6HourRentals"] as? Bool ?? false
        let allow24HourRentals = data["allow24HourRentals"] as? Bool ?? false
        let eympaFeePerHour = data["eympaFeePerHour"] as? Double ?? 0.0
        let userPricePerHour = data["userPricePerHour"] as? Double ?? 0.0
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

        return Scooter(
            id: id, description: description, imageURL: imageURL, isAvailable: isAvailable,
            isBooked: isBooked, activeBooking: activeBooking, isFeatured: isFeatured,
            confirmationCode: confirmationCode, location: location, totalPricePerHour: totalPricePerHour, allow6HourRentals: allow6HourRentals, allow24HourRentals: allow24HourRentals,
            eympaFeePerHour: eympaFeePerHour, userPricePerHour: userPricePerHour,
            sixHourPrice: sixHourPrice, fullDayPrice: fullDayPrice, isElectric: isElectric,
            range: range, brand: brand, modelName: modelName, yearOfMake: yearOfMake,
            damages: damages, restrictions: restrictions, specialNotes: specialNotes,
            scooterName: scooterName, topSpeed: topSpeed, ownerID: ownerID, isConfirmed: isConfirmed,
            unavailableAt: unavailableAt, availability: availability
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 15) {
                        ZStack {
                            AsyncImage(url: faceImageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                                        .padding(.top, 5)
                                @unknown default:
                                    ProgressView()
                                        .frame(width: 120, height: 120)
                                }
                            }
                        }

                        Text("\(firstName) \(lastName)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(UIColor(hex: "primary")))

                        Text(email)
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor(hex: "primary")).opacity(0.8))

                        Text("Phone: \(phoneNumber)")
                            .font(.subheadline)
                            .foregroundColor(Color(UIColor(hex: "primary")).opacity(0.8))

                        Button(action: {
                            isEditing = true
                        }) {
                            Text("Edit Profile")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(LinearGradient(
                                    colors: [Color(UIColor(hex: "primary")), Color(UIColor(hex: "primary")).opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .cornerRadius(15)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                    }

                    // Your Scooters Section
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("Your Garage")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(UIColor(hex: "secondary")))

                            Spacer()
                            
                            Button(action: {
                                showScooterPickupView = true
                            }) {
                                Image(systemName: "camera")
                                    .font(.title)
                                    .foregroundColor(Color(UIColor(hex: "secondary")))
                            }
                            
                            Button(action: {
                                showingAddScooterView = true
                            }) {
                                Image(systemName: "plus.circle")
                                    .font(.title)
                                    .foregroundColor(Color(UIColor(hex: "secondary")))
                            }
                            
                            Button(action: {
                                showBookingView = true
                            }) {
                                Image(systemName: "calendar")
                                    .font(.title)
                                    .foregroundColor(Color(UIColor(hex: "secondary")))
                            }
                            
                            Button(action: {
                                showPrevRentalsView = true
                            }) {
                                Image(systemName: "scooter")
                                    .font(.title)
                                    .foregroundColor(Color(UIColor(hex: "secondary")))
                            }
                            
                            .sheet(isPresented: $showingAddScooterView) {
                                AddScooterView()
                            }
                            .sheet(isPresented: $showScooterPickupView) {
                               ScooterPickupView()
                            }
                        }
                        .padding(.horizontal)

                        if let errorMessage = dataManager.errorMessage {
                            Text(errorMessage)
                                .font(.headline)
                                .foregroundColor(.red.opacity(0.8))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.purple.opacity(0.5))
                                .cornerRadius(15)
                                .padding(.horizontal)
                        } else if isLoading {
                            ProgressView("Loading scooters...")
                                .padding()
                                .foregroundColor(.white)
                        } else {
                            if userScooters.isEmpty {
                                ScrollView{
                                    VStack(spacing: 20) {
                                        // Scooter Graphic with Animation
                                        ZStack {
                                            Circle()
                                                .fill(LinearGradient(
                                                    colors: [Color(UIColor(hex: "primary")).opacity(0.2), Color.white],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                ))
                                                .frame(width: 200, height: 200)
                                            Image(systemName: "scooter")
                                                .font(.system(size: 100))
                                                .foregroundColor(Color(UIColor(hex: "primary")))
                                                .rotationEffect(.degrees(10))
                                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                                                .offset(x: -10, y: -10)
                                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: UUID())
                                        }
                                        .padding(.top, 20)
                                        
                                        Text("Your Garage is Empty!")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(UIColor(hex: "secondary")))
                                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                                        
                                        Text("Rev up your profile by adding a scooter\nto share with the community!")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                        
                                        // Action Buttons
                                        HStack(spacing: 15) {
                                            Button(action: {
                                                showingAddScooterView = true
                                            }) {
                                                Text("Add Scooter")
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.white)
                                                    .padding(.vertical, 12)
                                                    .padding(.horizontal, 20)
                                                    .background(LinearGradient(
                                                        colors: [Color(UIColor(hex: "primary")), Color(UIColor(hex: "primary")).opacity(0.7)],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    ))
                                                    .cornerRadius(10)
                                                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                                            }
                                            
                                            Button(action: {
                                                showScooterPickupView = true
                                            }) {
                                                Text("Learn More")
                                                    .fontWeight(.medium)
                                                    .foregroundColor(Color(UIColor(hex: "secondary")))
                                                    .padding(.vertical, 12)
                                                    .padding(.horizontal, 20)
                                                    .background(Color.white)
                                                    .cornerRadius(10)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(Color(UIColor(hex: "secondary")), lineWidth: 1)
                                                    )
                                            }
                                        }
                                        .padding(.bottom, 20)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(20)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                    .padding(.horizontal)
                                }
                            } else {
                                ScrollView(.vertical, showsIndicators: false) {
                                    VStack(spacing: 15) {
                                        ForEach(userScooters) { scooter in
                                            ScooterCard(scooter: scooter, onDelete: { selectedScooter in
                                                deleteScooter(selectedScooter)
                                            })
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .frame(maxHeight: .infinity) // Ensure it takes up available space
                }
                .padding(.top, 10)
            }
            .background(Color(red: 0.95, green: 0.96, blue: 0.97))
            .sheet(isPresented: $isEditing) {
                EditProfileView(
                    firstName: $firstName,
                    lastName: $lastName,
                    phoneNumber: $phoneNumber,
                    onSave: saveProfileChanges
                )
            }
            .onAppear {
                dataManager.fetchScooters()
                fetchUserProfile()
                fetchUserScooters()
                fetchFaceImageURL()
            }
            .navigationBarTitle("User Profile", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    withAnimation {
                        showScooterListView.toggle()
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                        Text("Back")
                            .font(.system(size: 18, weight: .medium))
                    }
                    .foregroundColor(Color(UIColor(hex: "secondary")))
                },
                trailing: Button(action: {
                    withAnimation {
                        showSignOutAlert = true
                    }
                }) {
                    HStack {
                        Text("Sign Out")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(.red))
                    }
                    .foregroundColor(Color(UIColor(hex: "secondary")))
                }
                .alert(isPresented: $showSignOutAlert) {
                    Alert(
                        title: Text("Sign Out"),
                        message: Text("Are you sure you want to sign out?"),
                        primaryButton: .destructive(Text("Sign Out")) {
                            do {
                                try Auth.auth().signOut()
                                print("User signed out successfully")
                                showContentView.toggle()
                            } catch {
                                print("Error signing out: \(error.localizedDescription)")
                            }
                        },
                        secondaryButton: .cancel()
                    )
                }
            )
        }
        .onAppear {
            fetchUserScooters()
        }
        .fullScreenCover(isPresented: $showContentView) {
            ContentView()
        }
        .fullScreenCover(isPresented: $showBookingView) {
            PreviousBookingsView(userId: Auth.auth().currentUser?.uid ?? "")
        }
        .fullScreenCover(isPresented: $showPrevRentalsView) {
            OwnerPastRentalsView(ownerId: Auth.auth().currentUser?.uid ?? "")
        }
        
        .overlay(
            Group {
                if showScooterListView {
                    ScooterListView()
                        .transition(.move(edge: .leading))
                        .zIndex(1)
                }
            }
        )
    }

    private func fetchUserProfile() {
        if let user = Auth.auth().currentUser {
            self.email = user.email ?? "No email found"
            self.identification = user.uid

            let db = Firestore.firestore()
            db.collection("Users")
                .whereField("schoolEmail", isEqualTo: user.email ?? "")
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("Error fetching user data: \(error.localizedDescription)")
                    } else {
                        if let document = snapshot?.documents.first {
                            self.firstName = document.data()["firstName"] as? String ?? "John"
                            self.lastName = document.data()["lastName"] as? String ?? "Doe"
                            self.phoneNumber = document.data()["phoneNumber"] as? String ?? "123-456-7890"
                            self.personalID = document.data()["id"] as? String ?? "n/a"
                            fetchUserScooters()
                        }
                    }
                }
        }
    }
    
    private func fetchFaceImageURL() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("users/\(userID)/face.jpg")
        storageRef.downloadURL { url, error in
            if let error = error {
                print("Error fetching face image URL: \(error.localizedDescription)")
                self.faceImageURL = nil
            } else {
                self.faceImageURL = url
            }
        }
    }
    
    private func deleteScooter(_ scooter: Scooter) {
        let db = Firestore.firestore()
        db.collection("Scooters").document(scooter.id).delete { error in
            if let error = error {
                print("Error deleting scooter: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.userScooters.removeAll { $0.id == scooter.id }
                }
                print("Scooter deleted successfully.")
            }
        }
    }

    private func saveProfileChanges(newFirstName: String, newLastName: String, newPhoneNumber: String) {
        let db = Firestore.firestore()
        if let userID = Auth.auth().currentUser?.uid {
            db.collection("Users").document(userID).updateData([
                "firstName": newFirstName,
                "lastName": newLastName,
                "phoneNumber": newPhoneNumber
            ]) { error in
                if let error = error {
                    print("Error updating user profile: \(error.localizedDescription)")
                } else {
                    self.firstName = newFirstName
                    self.lastName = newLastName
                    self.phoneNumber = newPhoneNumber
                    print("Profile updated successfully")
                }
            }
        }
    }
}

struct EditProfileView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var phoneNumber: String
    var onSave: (String, String, String) -> Void

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            VStack {
                Text("Edit Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)

                Text("Update your personal information")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor(hex: "primary")))
            .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
            .shadow(color: Color(UIColor(hex: "secondary")).opacity(0.2), radius: 5, x: 0, y: 5)

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("First Name")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    TextField("Enter first name", text: $firstName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .shadow(color: Color(UIColor(hex: "secondary")).opacity(0.1), radius: 2, x: 0, y: 2)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Name")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    TextField("Enter last name", text: $lastName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .shadow(color: Color(UIColor(hex: "secondary")).opacity(0.1), radius: 2, x: 0, y: 2)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    iPhoneNumberField("Phone", text: $phoneNumber)
                                        .flagHidden(false) // Display country flag
                                        .flagSelectable(true) // Allow country selection
                                        .font(.body)
                                        .padding()
                                        .background(RoundedRectangle(cornerRadius: 8).strokeBorder())
                                        .onChange(of: phoneNumber) { newValue in
                                            phoneNumber = formatPhoneNumber(newValue)
                                        }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color(UIColor(hex: "secondary")).opacity(0.1), radius: 5, x: 0, y: 5)
            .padding(.horizontal)

            Spacer()

            Button(action: {
                onSave(firstName, lastName, phoneNumber)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Save Changes")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(gradient: Gradient(colors: [Color(UIColor(hex: "primary")), Color(UIColor(hex: "primary")).opacity(0.7)]),
                                               startPoint: .top, endPoint: .bottom))
                    .cornerRadius(15)
                    .shadow(color: Color(UIColor(hex: "secondary")).opacity(0.2), radius: 5, x: 0, y: 5)
            }
            .padding(.horizontal)

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .padding(.top, 10)
        .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
    }
    
    private func formatPhoneNumber(_ phoneNumber: String) -> String {
        // Remove all non-digit characters using a regular expression
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // Check if we have enough digits to format, then format it
        if cleaned.count == 10 {
            let areaCode = cleaned.prefix(3)
            let midSection = cleaned.dropFirst(3).prefix(3)
            let lastSection = cleaned.dropFirst(6).prefix(4)
            return "+1 \(areaCode) \(midSection)-\(lastSection)"
        } else {
            // If not enough digits, return an empty string or handle as you see fit
            return phoneNumber
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct ScooterCard: View {
    var scooter: Scooter
    let onDelete: (Scooter) -> Void
    
    @State private var isCurrentlyAvailable: Bool = false
    @State private var showAvailabilityView = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showBookingConfirmationView = false
    @State private var isBooked: Bool = false
    @State private var showingSaveAlert: Bool = false
    @State private var bookingId: String = ""
    @State private var showFeatureConfirmation = false
    @State private var isProcessingPayment = false
    @State private var paymentCoordinator: ApplePayCoordinator?

    init(scooter: Scooter, onDelete: @escaping (Scooter) -> Void) {
        self.scooter = scooter
        self.onDelete = onDelete
        _isBooked = State(initialValue: scooter.isBooked)
    }

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: scooter.imageURL)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 100, height: 100)
            .cornerRadius(8)
            .clipped()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(scooter.scooterName)
                        .font(.system(size: 18, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                    AvailabilityBadge(isAvailable: isCurrentlyAvailable)
                }
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(scooter.location)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                HStack(spacing: 12) {
                    Text("$\(String(format: "%.2f", scooter.sixHourPrice))/6hr • $\(String(format: "%.2f", scooter.fullDayPrice))/day")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(UIColor(hex: "primary")))
                    if scooter.isFeatured {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "FFD700"))
                    }
                }

                Menu {
                    if isBooked && !bookingId.isEmpty {
                        Button(action: { showBookingConfirmationView = true }) {
                            Label("View Booking", systemImage: "eye")
                        }
                    } else if !scooter.activeBooking {
                        Button(action: { showAvailabilityView = true }) {
                            Label("Set Availability", systemImage: "calendar")
                        }
                    }
                    if !scooter.isFeatured {
                        Button(action: { showFeatureConfirmation = true }) {
                            Label(isProcessingPayment ? "Processing..." : "Feature Scooter", systemImage: "star")
                        }
                        .disabled(isProcessingPayment)
                    }
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        Label("Delete Scooter", systemImage: "trash")
                    }
                } label: {
                    Text(scooter.activeBooking ? "Booking Active" : "Manage")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(scooter.activeBooking ? Color.gray.opacity(0.5) : Color(UIColor(hex: "primary")))
                        .cornerRadius(8)
                }
                .disabled(scooter.activeBooking)
            }
            .frame(maxHeight: 100)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            checkCurrentAvailability()
            fetchBooking(scooter: scooter)
        }
        .sheet(isPresented: $showAvailabilityView) {
            ScooterAvailabilitySheetView(scooter: scooter)
        }
        .fullScreenCover(isPresented: $showBookingConfirmationView) {
            BookingConfirmationView(bookingId: bookingId)
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Scooter"),
                message: Text("Are you sure? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) { onDelete(scooter) },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showFeatureConfirmation) {
            Alert(
                title: Text("Feature Scooter"),
                message: Text("Feature this scooter for $1?"),
                primaryButton: .default(Text("Yes")) { processFeaturePayment() },
                secondaryButton: .cancel()
            )
        }
    }

    private func processFeaturePayment() {
        guard PKPaymentAuthorizationController.canMakePayments() else {
            print("Apple Pay not available")
            return
        }
        
        isProcessingPayment = true
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.Scootal.scootal"
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "US"
        request.currencyCode = "USD"
        request.paymentSummaryItems = [PKPaymentSummaryItem(label: "Feature Scooter Listing", amount: NSDecimalNumber(value: 1.00))]
        
        let paymentController = PKPaymentAuthorizationController(paymentRequest: request)
        paymentCoordinator = ApplePayCoordinator(
            didAuthorizePayment: { success in
                if success { updateScooterFeaturedStatus() }
                DispatchQueue.main.async {
                    self.isProcessingPayment = false
                    self.paymentCoordinator = nil
                }
            },
            didFinish: {
                DispatchQueue.main.async {
                    self.isProcessingPayment = false
                    self.paymentCoordinator = nil
                }
            }
        )
        paymentController.delegate = paymentCoordinator
        paymentController.present { success in
            if !success {
                print("Failed to present payment controller")
                DispatchQueue.main.async { self.isProcessingPayment = false }
            }
        }
    }

    private func updateScooterFeaturedStatus() {
        let db = Firestore.firestore()
        db.collection("Scooters").document(scooter.id).updateData(["isFeatured": true]) { error in
            if let error = error { print("Error updating featured status: \(error.localizedDescription)") }
            else { print("Scooter successfully featured") }
        }
    }

    private func checkCurrentAvailability() {
        let db = Firestore.firestore()
        db.collection("Scooters").document(scooter.id).getDocument { (document, error) in
            if let document = document, document.exists,
               let availabilityData = document.data()?["availability"] as? [String: Any] {
                let currentDay = Calendar.current.component(.weekday, from: Date()) - 1
                let daysOfWeek = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
                let currentDayString = daysOfWeek[currentDay]
                
                if let dayAvailability = availabilityData[currentDayString] as? [String: Any],
                   let isAvailable = dayAvailability["isAvailable"] as? Bool,
                   let startTimeString = dayAvailability["startTime"] as? String,
                   let endTimeString = dayAvailability["endTime"] as? String,
                   let startTime = DateFormatter.hhmm.date(from: startTimeString),
                   let endTime = DateFormatter.hhmm.date(from: endTimeString) {
                    
                    let currentTime = Date()
                    let calendar = Calendar.current
                    let startOfDay = calendar.startOfDay(for: currentTime)
                    let currentComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
                    let currentTimeDate = calendar.date(bySettingHour: currentComponents.hour!, minute: currentComponents.minute!, second: 0, of: startOfDay)!
                    let startTimeDate = calendar.date(bySettingHour: calendar.component(.hour, from: startTime), minute: calendar.component(.minute, from: startTime), second: 0, of: startOfDay)!
                    let endTimeDate = calendar.date(bySettingHour: calendar.component(.hour, from: endTime), minute: calendar.component(.minute, from: endTime), second: 0, of: startOfDay)!
                    
                    isCurrentlyAvailable = isAvailable && (currentTimeDate >= startTimeDate && currentTimeDate <= endTimeDate)
                }
            }
        }
    }

    private func fetchBooking(scooter: Scooter) {
        let db = Firestore.firestore()
        db.collection("Bookings")
            .whereField("scooterID", isEqualTo: scooter.id)
            .whereField("isRejected", isEqualTo: false)
            .whereField("isAccepted", isEqualTo: false)
            .whereField("isActive", isEqualTo: false)
            .getDocuments { snapshot, error in
                if let error = error { print("Error fetching booking data: \(error.localizedDescription)") }
                else if let document = snapshot?.documents.first {
                    self.bookingId = document.documentID
                } else {
                    self.bookingId = ""
                }
            }
    }
}

extension DateFormatter {
    static let hhmm: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

struct AvailabilityBadge: View {
    let isAvailable: Bool
    var body: some View {
        Text(isAvailable ? "Available" : "Unavailable")
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(isAvailable ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .foregroundColor(isAvailable ? .green : .red)
            .cornerRadius(4)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

struct PricingInfo: View {
    let price: Double
    let label: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("$\(price, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor(hex: "primary")))
            .foregroundColor(.white)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor(hex: "accent")))
            .foregroundColor(.white)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
    }
}
