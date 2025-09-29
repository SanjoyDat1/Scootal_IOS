//
//  ForgotPassword.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2024-12-15.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ForgotPassword: View {
    @Binding var showResetView: Bool
    
    @State private var emailID: String = ""
    @State private var message: String = "" // To show success or error messages
    @State private var messageColor: Color = .gray
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15, content: {
            
            Button(action: {
                dismiss()
            }, label: {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundStyle(.gray)
            })
            
            Text("Forgot Password?")
                .font(.largeTitle)
                .fontWeight(.heavy)
            
            Text("Please enter your Email ID so that we can send the reset link.")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.gray)
                .padding(.top, -5)
                
            VStack(spacing: 25) {
                TempTextField(sfIcon: "at", hint: "Email ID", value: $emailID)
                
                GradientButton(title: "Send Link", icon: "arrow.right") {
                    // Send the link to the email here
                    sendPasswordResetEmail(email: emailID)
                }
                .hSpacing(.trailing)
                .disableWithOpacity(emailID.isEmpty)
            }
            .padding(.top, 20)
            
            // Message display for success/error
            Text(message)
                .foregroundColor(messageColor)
                .padding(.top, 15)
        })
        .padding(.vertical, 15)
        .padding(.horizontal, 25)
        .interactiveDismissDisabled()
    }
    
    private func sendPasswordResetEmail(email: String) {
        checkIfEmailExists(email: email) {exists in
            if exists{
                Auth.auth().sendPasswordReset(withEmail: email) { error in
                    if let error = error {
                        // If error occurs, show error message
                        message = "Error: \(error.localizedDescription)"
                        messageColor = .red
                    } else {
                        // If email is sent successfully, show success message
                        message = "Password reset email sent."
                        messageColor = .green
                    }
                }
            } else {
                message = "Error: email not found."
                messageColor = .red
            }
        }
    }
    
    func checkIfEmailExists(email: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        // Query the Users collection for a document with the matching email
        db.collection("Users")
            .whereField("emailID", isEqualTo: email.lowercased())
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    message = ("Error: \(error.localizedDescription)")
                    completion(false) // Consider email not found in case of error
                    return
                }
                
                // Check if any documents were returned
                if let snapshot = querySnapshot, !snapshot.isEmpty {
                    print("Email exists in Users collection.")
                    completion(true)
                } else {
                    print("Email does not exist in Users collection.")
                    completion(false)
                }
            }
    }
}

#Preview {
    ContentView()
}
