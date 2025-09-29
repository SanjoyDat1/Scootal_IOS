//
//  Login.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2024-12-15.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct Login: View {
    @Binding var showSignup: Bool
    
    @State private var emailID: String = ""
    @State private var password: String = ""
    @State private var showForgetPasswordView: Bool = false
    @State private var showResetView: Bool = false
    @State private var userIsLoggedIn: Bool = false
    @State private var showScooterListView: Bool = false

    var body: some View {
        VStack {
            
        VStack(spacing: 5) {
            Text("Scootal")
                .font(.system(size: 50, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor(hex: "primary")))
            
            Text("Find Your Next Ride")
                .font(.system(size: 17, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor(hex: "primary")))
        }
        .frame(maxWidth: .infinity) // Ensure it's centered
        .padding(.top, 30)
        .padding(.bottom, -30)
        
        VStack(alignment: .leading, spacing: 15, content: {
            Spacer (minLength: 0)
            
            Text("Login")
                .font(.largeTitle)
                .foregroundColor(Color(UIColor(hex: "secondary")))
                .fontWeight(.heavy)
            
            Text("Please sign in to continue")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(UIColor(hex: "secondary")).opacity(0.7))
                .padding(.top, -5)
                
            VStack(spacing: 25) {
                TempTextField(sfIcon: "at", hint: "Email ID", value: $emailID)
                TempTextField(sfIcon: "lock", hint: "Password",isPassword: true, value: $password)
                    .padding(.top, 5)
                Button("Forgot Password?"){
                    showForgetPasswordView.toggle()
                }
                .font(.callout)
                .fontWeight(.heavy)
                .tint(Color(UIColor(hex: "primary")))
                .hSpacing(.trailing)
                GradientButton(title: "Login", icon: "arrow.right"){
                    LoginUser()
                }
                .hSpacing(.trailing)
                .disableWithOpacity(emailID.isEmpty || password.isEmpty)
            }
            .padding(.top, 20)
            
            Spacer(minLength: 0)
            
            HStack(spacing: 6) {
                Text("Don't have an account?")
                    .foregroundStyle(.gray)
                Button("Sign-Up") {
                    showSignup = true
                }
                .fontWeight(.bold)
                .tint(Color(UIColor(hex: "primary")))
            }
        })
        .padding(.vertical, 15)
        .padding(.horizontal, 25)
        .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showForgetPasswordView, content: {
            if #available(iOS 16.4, *){
                ForgotPassword(showResetView: $showResetView)
                    .presentationDetents([.height(350)])
                    .presentationCornerRadius(30)
            } else {
                ForgotPassword(showResetView: $showResetView)
                    .presentationDetents([.height(350)])
            }
        })
        .fullScreenCover(isPresented: $showScooterListView) {
                    ScooterListView() // Show ScooterListView when true
                }
        .fullScreenCover(isPresented: $showSignup) {
            ScootalSignUp() // Show ScooterListView when true
        }
        .overlay {
            if #available(iOS 16, *){
                CircleView()
                    .animation(.smooth(duration: 0.45, extraBounce: 0.25), value: showSignup)
            } else {
                CircleView()
                    .animation(.easeInOut(duration: 0.35), value: showSignup)
            }
        }
    }

    private func LoginUser() {
        Auth.auth().signIn(withEmail: emailID, password: password) { authResult, error in

            guard let user = Auth.auth().currentUser else {

                return
            }

            if user.isEmailVerified {
                // Proceed to the app
                print("Login successful. Email is verified.")
                showScooterListView = true
                
                
            } else{
                do {
                        try Auth.auth().signOut()
                        print("User signed out successfully.")
                        // Navigate to the login screen or update the UI
                } catch let signOutError as NSError {
                    print("Error signing out: \(signOutError.localizedDescription)")
                }
            }
        }
    }
    
    func CircleView() -> some View{
        Circle()
            .fill(.linearGradient(colors: [Color(UIColor(hex: "primary")), Color(UIColor(hex: "primary")).opacity(0.2)], startPoint: .top, endPoint: .bottom))
            .frame(width: 200, height: 200)
        
            .offset(x: -290, y: showSignup ? -400: -160)
            .blur(radius: 15)
            .hSpacing(.trailing)
            .vSpacing(.top)
    }
}

#Preview {
    ContentView()
}
