//
//  SchoolRequestView.swift
//  Scootal
//
//  Created by Sanjoy Datta on 2025-03-30.
//

import SwiftUI
import FirebaseFirestore

struct SchoolRequestView: View {
    // MARK: - State Properties
    @State private var reqFirstName: String = ""
    @State private var reqLastName: String = ""
    @State private var reqSchoolName: String = ""
    @State private var reqSchoolEmail: String = ""
    @State private var showSignup: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isSuccess: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Firebase Reference
    private let db = Firestore.firestore()
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    headerSection
                    descriptionSection
                    formSection
                }
                .padding()
                .disabled(isSubmitting)
            }
            .navigationBarItems(leading: customBackButton)
            .overlay(circleOverlay)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(isSuccess ? "Success" : "Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if isSuccess {
                            dismiss()
                        }
                    }
                )
            }
        }
        .animation(.easeInOut, value: isSubmitting)
    }
    
    // MARK: - View Components
    private var headerSection: some View {
        Text("Request Scootal")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(Color(UIColor(hex: "primary")))
            .padding(.top, 20)
    }
    
    private var descriptionSection: some View {
        Text("If Scootal is not currently located at your school, please fill out the fields below and we will get back to you as soon as possible.")
            .font(.body)
            .fontWeight(.bold)
            .foregroundColor(Color(UIColor(hex: "secondary")).opacity(0.6))
    }
    
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            CustomTextField(placeholder: "First Name", text: $reqFirstName, icon: "person")
                .textContentType(.givenName)
            CustomTextField(placeholder: "Last Name", text: $reqLastName, icon: "person")
                .textContentType(.familyName)
            CustomTextField(placeholder: "School Email", text: $reqSchoolEmail, icon: "envelope", keyboardType: .emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            CustomTextField(placeholder: "School Name", text: $reqSchoolName, icon: "building", keyboardType: .default)
                .textContentType(.organizationName)
            
            Button(action: submitRequest) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                    Text(isSubmitting ? "Submitting..." : "Submit Request")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(FirstButtonStyle())
            .disabled(!isFormValid || isSubmitting)
            .opacity(!isFormValid && !isSubmitting ? 0.6 : 1.0)
        }
    }
    
    private var circleOverlay: some View {
        CircleView()
            .animation(.easeInOut(duration: 0.35), value: showSignup)
    }
    
    private var customBackButton: some View {
        Button(action: {
            dismiss()
            showSignup.toggle()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 5)
            .foregroundColor(Color(UIColor(hex: "secondary")))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func CircleView() -> some View {
        Circle()
            .fill(.linearGradient(colors: [Color(UIColor(hex: "007AFF")), Color(UIColor(hex: "007AFF")).opacity(0.2)], startPoint: .top, endPoint: .bottom))
            .frame(width: 200, height: 200)
            .offset(x: 40, y: showSignup ? -300 : -180)
            .blur(radius: 15)
            .hSpacing(.trailing)
            .vSpacing(.top)
    }
    
    // MARK: - Firebase Submission
    private func submitRequest() {
        guard isFormValid else { return }
        
        isSubmitting = true
        let requestData: [String: Any] = [
            "firstName": reqFirstName,
            "lastName": reqLastName,
            "schoolName": reqSchoolName,
            "schoolEmail": reqSchoolEmail,
            "timestamp": FieldValue.serverTimestamp(),
            "status": "pending",
            "submissionDate": ISO8601DateFormatter().string(from: Date())
        ]
        
        db.collection("schoolRequests").addDocument(data: requestData) { error in
            DispatchQueue.main.async {
                isSubmitting = false
                if let error = error {
                    alertMessage = "Failed to submit request: \(error.localizedDescription)"
                    isSuccess = false
                } else {
                    alertMessage = "Your request has been submitted successfully!\nWe'll get back to you soon."
                    isSuccess = true
                    clearForm()
                }
                showAlert = true
            }
        }
    }
    
    // MARK: - Form Validation
    private var isFormValid: Bool {
        !reqFirstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !reqLastName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !reqSchoolName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !reqSchoolEmail.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidEmail(reqSchoolEmail)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Helper Methods
    private func clearForm() {
        reqFirstName = ""
        reqLastName = ""
        reqSchoolName = ""
        reqSchoolEmail = ""
    }
}


#Preview {
    SchoolRequestView()
}
