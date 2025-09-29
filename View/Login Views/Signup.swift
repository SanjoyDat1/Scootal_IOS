//
//  Signup.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2024-12-15.
//

import SwiftUI
import Firebase
import FirebaseAuth
import UIKit

struct Signup: View {
    @Binding var showSignup: Bool
    
    @State private var emailID: String = ""
    @State private var phoneNumber: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15, content: {
            
            Button(action: {
                showSignup = false
            }, label: {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundStyle(.gray)
            })
            
            Text("Sign-Up")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(Color(UIColor(hex: "secondary")))
            
            Text("Please sign-up to continue")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(UIColor(hex: "secondary")).opacity(0.7))
                .padding(.top, -5)
            
            VStack(spacing: 25) {
                
                TempTextField(sfIcon: "person", hint: "First Name", value: $firstName)
                    .padding(.top, 5)
                
                TempTextField(sfIcon: "person", hint: "Last Name", value: $lastName)
                    .padding(.top, 5)
                
                TempTextField(sfIcon: "at", hint: "Email ID", value: $emailID)
                TempTextField(sfIcon: "phone", hint: "Phone Number", value: $phoneNumber)
                
                TempTextField(sfIcon: "lock", hint: "Password", isPassword: true, value: $password)
                    .padding(.top, 5)
                
                TempTextField(sfIcon: "lock", hint: "Confirm Password", isPassword: true, value: $confirmPassword)
                    .padding(.top, 5)
                
                GradientButton(title: "Continue", icon: "arrow.right") {
                    createUser()
                }
                .hSpacing(.trailing)
                .disableWithOpacity(emailID.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty || phoneNumber.isEmpty || password != confirmPassword)
            }
            .padding(.top, 20)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .font(.system(size: 15))
                    .lineLimit(3)
            }
            
            Spacer(minLength: 0)
            
            HStack(spacing: 6) {
                Text("Already have an account?")
                    .foregroundStyle(.gray)
                Button("Login") {
                    showSignup = false
                }
                .fontWeight(.bold)
                .tint(Color(UIColor(hex: "primary")))
            }
            .font(.callout)
            .hSpacing()
        })
        .padding(.vertical, 15)
        .padding(.horizontal, 25)
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private func createUser() {
        //guard let emailDomain = emailID.lowercased().components(separatedBy: "@").last, emailDomain == "uci.edu" else {
        //    errorMessage = "Only UC Irvine students can sign up. Please use an '@uci.edu' email."
        //    return
        //}

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match. Please try again."
            return
        }

        errorMessage = nil

        Auth.auth().createUser(withEmail: emailID, password: password) { authResult, error in
            if let error = error {
                errorMessage = "Error creating user: \(error.localizedDescription)"
                return
            }

            guard let user = authResult?.user else {
                errorMessage = "User creation failed. Please try again."
                return
            }

            // Send email verification
            user.sendEmailVerification { error in
                if let error = error {
                    errorMessage = "Error sending email verification: \(error.localizedDescription)"
                    return
                }

                print("Email verification sent to \(emailID). Please verify your email.")
                handleEmailVerification()
                errorMessage = "Verification email sent. Please check your inbox and verify."
                
            }
        }
    }

    // Separate function to handle email verification
    func handleEmailVerification() {
        Auth.auth().currentUser?.reload { error in
            if let error = error {
                errorMessage = "Error reloading user data: \(error.localizedDescription)"
                return
            }
            let user = Auth.auth().currentUser
            // Save user information in Firestore
            let db = Firestore.firestore()
            let userData: [String: Any] = [
                "firstName": firstName,
                "lastName": lastName,
                "emailID": emailID.lowercased(),
                "phoneNumber": phoneNumber,
                "id": user?.uid,
                "isEmailVerified": user?.isEmailVerified
            ]

            db.collection("Users").document(user!.uid).setData(userData) { error in
                if let error = error {
                    errorMessage = "Error saving user data: \(error.localizedDescription)"
                } else {
                    print("User data saved successfully.")
                    showSignup = false
                }
            }
        }
    }
}





    
    
    #Preview {
        ContentView ()
    }
