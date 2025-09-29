import SwiftUI
import Firebase

struct ConfirmationCodeView: View {
    var scooter: Scooter // The scooter being booked
    @Binding var confirmationCode: String // The confirmation code entered by the user
    var onConfirm: () -> Void // Function to call when booking is confirmed
    var onCancel: () -> Void // Function to call when the booking is canceled
    @State private var errorMessage: String? // To show error if confirmation fails
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 30) {
            // Title Section
            
            
            Text("Confirm Your Booking")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.purple)
                .multilineTextAlignment(.center)
                .padding(.top, 20)

            Text("Enter the 6-digit confirmation code for \(scooter.scooterName)")
                .font(.subheadline)
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Single Text Field for Confirmation Code
            TextField("Enter Confirmation Code", text: $confirmationCode)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.center)
                .font(.title)
                .padding(.horizontal, 40)
                .onChange(of: confirmationCode) { newValue in
                    // Limit to 6 digits
                    confirmationCode = String(newValue.prefix(6))
                }

            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 5)
            }

            // Confirm Button
            Button(action: {
                validateConfirmationCode()
            }) {
                Text("Confirm Booking")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .disabled(confirmationCode.count != 6)
            .opacity(confirmationCode.count != 6 ? 0.5 : 1.0)

            // Cancel Button
            Button(action: {
                onCancel()
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .fontWeight(.bold)
                    .foregroundColor(Color.purple)
            }
            .padding(.top, 10)

            Spacer()
        }
        .padding()
    }

    private func validateConfirmationCode() {
        let db = Firestore.firestore()
        let scooterRef = db.collection("Scooters").document(scooter.id)

        scooterRef.getDocument { (document, error) in
            if let error = error {
                errorMessage = "Error retrieving scooter details: \(error.localizedDescription)"
                return
            }

            guard let document = document, document.exists else {
                errorMessage = "Scooter not found."
                return
            }

            let storedCode = document.get("confirmationCode") as? String ?? ""

            if storedCode == confirmationCode {
                scooterRef.updateData([
                    "isBooked": true,
                    "confirmationCode": ""
                ]) { error in
                    if let error = error {
                        errorMessage = "Error confirming booking: \(error.localizedDescription)"
                    } else {
                        onConfirm()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } else {
                errorMessage = "Incorrect confirmation code. Please try again."
            }
        }
    }
}

