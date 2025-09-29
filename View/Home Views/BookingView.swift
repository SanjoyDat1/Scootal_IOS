import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions
import StripePaymentSheet
import Stripe
import StripeConnect
import UIKit // For UIApplication

struct BookingView: View {
    let scooter: Scooter
    let startTime: Date
    let endTime: Date
    let selectedDuration: Int
    @State private var confirmationCode: String = String(Int.random(in: 100000...999999))
    @State private var safetyAcknowledged: Bool = false
    @State private var showingConfirmation: Bool = false
    @State private var isProcessingPayment: Bool = false
    @State private var showAlert: Bool = false
    @State private var paymentError: IdentifiableError?
    @State private var paymentSheet: PaymentSheet?
    @State private var providerNotOnboarded: Bool = false
    @Environment(\.presentationMode) var presentationMode
    
    private let functions = Functions.functions()
    
    var basePrice: Double {
        switch selectedDuration {
        case 6:
            print("Base price for 6 hours: \(scooter.sixHourPrice)")
            return scooter.sixHourPrice
        case 24:
            print("Base price for 24 hours: \(scooter.fullDayPrice)")
            return scooter.fullDayPrice
        default:
            print("Invalid duration selected: \(selectedDuration) hours")
            return 0
        }
    }
    
    let unlockFee: Double = 1.00
    let feesAndTaxesRate: Double = 0.15
    
    var totalPrice: Double {
        let feesAndTaxes = basePrice * feesAndTaxesRate
        let calculatedTotal = basePrice + unlockFee + feesAndTaxes
        let roundedTotal = (calculatedTotal * 100).rounded() / 100
        print("Calculating totalPrice: basePrice=\(basePrice), unlockFee=\(unlockFee), feesAndTaxes=\(feesAndTaxes), total=\(calculatedTotal), roundedTotal=\(roundedTotal)")
        return roundedTotal
    }
    
    let readableDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    scooterDetailsCard
                    durationSelectionView
                    pricingSummaryView
                    safetyGuidelinesView
                    bookingButton
                }
                .padding()
            }
            .navigationBarTitle("Book Your Ride", displayMode: .inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Booking Confirmed"),
                    message: Text("Your booking has been successfully created. Confirmation code: \(confirmationCode)"),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
            .alert(item: $paymentError) { error in
                Alert(
                    title: Text("Payment Error"),
                    message: Text(error.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $providerNotOnboarded) {
                Alert(
                    title: Text("Provider Not Onboarded"),
                    message: Text("This scooter’s provider hasn’t set up payments yet. Would you like to notify them?"),
                    primaryButton: .default(Text("Notify")) {
                        onboardProvider()
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                StripeAPI.defaultPublishableKey = "pk_live_51QeTUuIWrE69S61q7W01X8ZQBk5fE92SFd5ociPzhp1ifM7ddoSJGrQJ9dVH0mXcmMH1L8vyNtJmx38kou01WuIs00hdlsuXF7"
                onboardProvider()
            }
        }
    }
    
    var headerView: some View {
        Text("Choose Your Rental Duration")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(Color(UIColor(hex: "primary")))
    }
    
    var scooterDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(scooter.scooterName)
                        .font(.headline)
                        .foregroundColor(Color(UIColor(hex: "primary")))
                    
                    if selectedDuration == 6 {
                        Text("$\(String(format: "%.2f", scooter.sixHourPrice))/6hrs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if selectedDuration == 24 {
                        Text("$\(String(format: "%.2f", scooter.fullDayPrice))/day")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "scooter")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(Color(UIColor(hex: "primary")))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    var durationSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rental Duration")
                .font(.headline)
                .foregroundColor(Color(UIColor(hex: "primary")))
            
            HStack(spacing: 16) {
                if selectedDuration == 6 {
                    durationButton(hours: 6)
                } else if selectedDuration == 24 {
                    durationButton(hours: 24)
                }
            }
        }
    }
    
    func durationButton(hours: Int) -> some View {
        VStack {
            Text("\(hours) hours")
                .font(.headline)
            VStack {
                if hours == 6 {
                    Text("$\(String(format: "%.2f", scooter.sixHourPrice))")
                        .font(.subheadline)
                } else if hours == 24 {
                    Text("$\(String(format: "%.2f", scooter.fullDayPrice))")
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(selectedDuration == hours ? Color(UIColor(hex: "primary")) : Color(UIColor.tertiarySystemBackground))
        .foregroundColor(selectedDuration == hours ? .white : Color(UIColor(hex: "primary")))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(UIColor(hex: "primary")), lineWidth: 2)
        )
    }
    
    var pricingSummaryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Booking Summary")
                .font(.headline)
                .foregroundColor(Color(UIColor(hex: "primary")))
            
            HStack {
                Text("Start Time:")
                Spacer()
                Text(readableDateFormatter.string(from: startTime))
            }
            
            HStack {
                Text("End Time:")
                Spacer()
                Text(readableDateFormatter.string(from: endTime))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Base Price:")
                    Spacer()
                    Text("$\(String(format: "%.2f", basePrice))")
                }
                HStack {
                    Text("Unlock Fee:")
                    Spacer()
                    Text("$\(String(format: "%.2f", unlockFee))")
                }
                HStack {
                    Text("Fees & Taxes (15%):")
                    Spacer()
                    Text("$\(String(format: "%.2f", basePrice * feesAndTaxesRate))")
                }
                Divider()
                HStack {
                    Text("Total Price:")
                    Spacer()
                    Text("$\(String(format: "%.2f", totalPrice))")
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .alert(isPresented: $showingConfirmation) {
            Alert(
                title: Text("Payment Successful"),
                message: Text("Your payment has been processed successfully!"),
                primaryButton: .default(Text("View Receipt")) {
                    // Add action, e.g., navigate to receipt
                },
                secondaryButton: .cancel(Text("OK"))
            )
        }
    }
    
    var safetyGuidelinesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Safety Guidelines")
                .font(.headline)
                .foregroundColor(Color(UIColor(hex: "primary")))
            
            VStack(alignment: .leading, spacing: 8) {
                safetyItem(icon: "helmet", text: "Wear a helmet at all times")
                safetyItem(icon: "exclamationmark.triangle", text: "Follow traffic rules")
                safetyItem(icon: "checkmark.shield", text: "Inspect the scooter before riding")
                safetyItem(icon: "phone", text: "Report any issues immediately")
            }
            
            Toggle(isOn: $safetyAcknowledged) {
                Text("I agree to follow the safety guidelines")
                    .font(.subheadline)
            }
            .toggleStyle(SwitchToggleStyle(tint: Color(UIColor(hex: "primary"))))
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    func safetyItem(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(UIColor(hex: "primary")))
            Text(text)
                .font(.subheadline)
        }
    }
    
    var bookingButton: some View {
        Button(action: {
            isProcessingPayment = true
            checkProviderOnboarding()
        }) {
            Text(isProcessingPayment ? "Processing..." : "Confirm Booking")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(safetyAcknowledged ? Color(UIColor(hex: "primary")) : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!safetyAcknowledged || isProcessingPayment)
    }
    
    func checkProviderOnboarding() {
        let db = Firestore.firestore()
        print("Checking provider onboarding for ownerID: \(scooter.ownerID)")
        db.collection("providers").document(scooter.ownerID).getDocument { snapshot, error in
            if let error = error {
                print("Error checking provider: \(error.localizedDescription)")
                paymentError = IdentifiableError(message: "Failed to verify provider: \(error.localizedDescription)")
                isProcessingPayment = false
                return
            }
            if snapshot?.exists == true {
                let data = snapshot!.data()!
                print("Provider document found: \(data)")
                if data["stripeAccountId"] != nil, data["onboarded"] as? Bool == true {
                    print("Provider \(scooter.ownerID) is fully onboarded, proceeding to payment")
                    preparePaymentSheet()
                } else {
                    print("Provider \(scooter.ownerID) exists but not fully onboarded: stripeAccountId=\(data["stripeAccountId"] ?? "nil"), onboarded=\(data["onboarded"] ?? false)")
                    providerNotOnboarded = true
                    isProcessingPayment = false
                }
            } else {
                print("No provider document found for \(scooter.ownerID)")
                providerNotOnboarded = true
                isProcessingPayment = false
            }
        }
    }
    
    func onboardProvider() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No authenticated user")
            paymentError = IdentifiableError(message: "You must be logged in")
            isProcessingPayment = false
            return
        }
        
        let db = Firestore.firestore()
        print("Starting onboarding for provider \(scooter.ownerID) by user \(currentUser.uid)")
        db.collection("Users").document(scooter.ownerID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching provider email: \(error.localizedDescription)")
                paymentError = IdentifiableError(message: "Failed to fetch provider details: \(error.localizedDescription)")
                isProcessingPayment = false
                return
            }
            guard let userData = snapshot?.data(),
                  let providerEmail = userData["email"] as? String else {
                print("No email for provider \(scooter.ownerID)")
                paymentError = IdentifiableError(message: "Provider email not found")
                isProcessingPayment = false
                return
            }
            
            print("Calling createConnectedAccount with email: \(providerEmail), ownerId: \(scooter.ownerID)")
            functions.httpsCallable("createConnectedAccount").call([
                "email": providerEmail,
                "ownerId": scooter.ownerID
            ]) { result, error in
                if let error = error {
                    print("Onboarding error: \(error.localizedDescription)")
                    paymentError = IdentifiableError(message: "Failed to start onboarding: \(error.localizedDescription)")
                    isProcessingPayment = false
                    return
                }
                guard let urlString = (result?.data as? [String: Any])?["url"] as? String,
                      let url = URL(string: urlString) else {
                    print("Invalid URL received: \(result?.data ?? [:])")
                    paymentError = IdentifiableError(message: "Invalid onboarding URL")
                    isProcessingPayment = false
                    return
                }
                print("Opening URL: \(urlString)")
                UIApplication.shared.open(url)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    checkProviderOnboarding()
                }
            }
        }
    }

    func preparePaymentSheet() {
        let amountInCents = Int(totalPrice * 100)
        print("Preparing PaymentSheet with amount: \(amountInCents) cents, providerId: \(scooter.ownerID), scooterId: \(scooter.id)")
        functions.httpsCallable("createPaymentIntent").call([
            "amount": amountInCents,
            "providerId": scooter.ownerID,
            "scooterId": scooter.id
        ]) { result, error in
            if let error = error {
                print("Error from Cloud Function: \(error.localizedDescription)")
                self.paymentError = IdentifiableError(message: "Failed to prepare payment: \(error.localizedDescription)")
                self.isProcessingPayment = false
                return
            }
            guard let clientSecret = (result?.data as? [String: Any])?["clientSecret"] as? String else {
                print("Invalid response from Cloud Function: \(result?.data ?? "No data")")
                self.paymentError = IdentifiableError(message: "Invalid payment response")
                self.isProcessingPayment = false
                return
            }
            
            print("Received clientSecret: \(clientSecret)")
            var config = PaymentSheet.Configuration()
            config.merchantDisplayName = "Scootal"
            config.allowsDelayedPaymentMethods = false
            self.paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
            print("PaymentSheet initialized successfully")
            processStripePayment()
        }
    }
    
    func processStripePayment() {
        print("Attempting to process payment. paymentSheet is \(paymentSheet == nil ? "nil" : "set")")
        guard let paymentSheet = paymentSheet else {
            paymentError = IdentifiableError(message: "Payment not ready. Please try again.")
            isProcessingPayment = false
            return
        }
        
        paymentSheet.present(from: UIApplication.shared.windows.first?.rootViewController ?? UIViewController()) { result in
            switch result {
            case .completed:
                saveBookingToFirebase()
                showingConfirmation = true
                showAlert = true
            case .canceled:
                paymentError = IdentifiableError(message: "Payment canceled")
            case .failed(let error):
                paymentError = IdentifiableError(message: "Payment failed: \(error.localizedDescription)")
            }
            isProcessingPayment = false
        }
    }
    
    private func saveBookingToFirebase() {
        let db = Firestore.firestore()
        let bookingID = UUID().uuidString
        let customerId = Auth.auth().currentUser?.uid ?? ""
        
        let endTimeTimestamp = Timestamp(date: endTime)
        
        let bookingData: [String: Any] = [
            "id": bookingID,
            "scooterID": scooter.id,
            "location": scooter.location,
            "topSpeed": scooter.topSpeed,
            "scooterName": scooter.scooterName,
            "isAccepted": false,
            "isActive": false,
            "isRejected": false,
            "endTime": endTimeTimestamp,
            "estimatedPrice": "$\(String(format: "%.2f", totalPrice))",
            "sixHourPrice": "$\(String(format: "%.2f", scooter.sixHourPrice))",
            "fullDayPrice": "$\(String(format: "%.2f", scooter.fullDayPrice))",
            "customerId": customerId,
            "ownerId": scooter.ownerID,
            "confirmationCode": confirmationCode,
            "unlockFee": "$\(String(format: "%.2f", unlockFee))",
            "feesAndTaxes": "$\(String(format: "%.2f", basePrice * feesAndTaxesRate))"
        ]
        
        db.collection("Bookings").document(bookingID).setData(bookingData) { error in
            if let error = error {
                print("Error creating booking: \(error.localizedDescription)")
            } else {
                print("Booking successfully saved to Firebase.")
                updateUserBookings(customerId: customerId, bookingID: bookingID)
                updateScooterStatus()
            }
        }
    }
    
    private func updateUserBookings(customerId: String, bookingID: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("Users").document(customerId)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                var bookings = document.data()?["bookings"] as? [String] ?? []
                bookings.append(bookingID)
                userRef.updateData(["bookings": bookings]) { error in
                    if let error = error {
                        print("Error updating user's bookings list: \(error.localizedDescription)")
                    } else {
                        print("User's bookings list updated successfully.")
                    }
                }
            } else {
                print("User document does not exist: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func updateScooterStatus() {
        let db = Firestore.firestore()
        let scooterRef = db.collection("Scooters").document(scooter.id)
        scooterRef.updateData(["isBooked": true]) { error in
            if let error = error {
                print("Error updating scooter booking status: \(error.localizedDescription)")
            } else {
                print("Scooter status updated to booked.")
            }
        }
    }
}

struct IdentifiableError: Identifiable {
    let id = UUID()
    let message: String
}
