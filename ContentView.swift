//
//  ContentView.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2024-12-15.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ContentView: View {
    @State private var isUserLoggedIn: Bool? = nil // Initially nil until check completes
    
    var body: some View {
        ZStack {
            if let isLoggedIn = isUserLoggedIn {
                if isLoggedIn {
                    ScooterListView()
                } else {
                    ScootalSignUp()
                }
            } else {
                // Show a loading view while checking auth state
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }
        }
        
        .onAppear {
            checkUserAuthStatus()
        }
        
    }
    
    private func checkUserAuthStatus() {
        // Check if there's a current user
        if let user = Auth.auth().currentUser {
            // Optionally verify email if your app requires it
            if user.isEmailVerified {
                isUserLoggedIn = true
                print("User is logged in with email: \(user.email ?? "unknown")")
            } else {
                // If email isn't verified, treat as not logged in
                isUserLoggedIn = false
                print("User email not verified: \(user.email ?? "unknown")")
            }
        } else {
            isUserLoggedIn = false
            print("No user is currently logged in")
        }
    }
}

#Preview {
    ContentView()
}
