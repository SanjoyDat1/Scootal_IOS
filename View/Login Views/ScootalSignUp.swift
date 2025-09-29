//
//  ScootalSignUp.swift
//  Scootal
//
//  Created by Sanjoy Datta on 2025-03-26.
//
import SwiftUI
import TOCropViewController
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import PhotosUI
import iPhoneNumberField

struct ScootalSignUp: View {
    @State private var formData = SignUpFormData()
    @State private var currentStep: Int = 1
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showSuccess: Bool = false
    @State private var showCropper: Bool = false
    @State private var showLoginView: Bool = false
    @State private var showSchoolRequest: Bool = false
    
    private let totalSteps = 5
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.bottom)
            
            VStack(spacing: 0) {
                ProgressHeader(step: currentStep, total: totalSteps)
                    .padding(.top, 5)
                
                ScrollView {
                    VStack(spacing: 32) {
                        stepContent
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                
                NavigationFooter(
                    currentStep: $currentStep,
                    showLoginView: $showLoginView,
                    totalSteps: totalSteps,
                    onNext: validateAndProceed,
                    onSubmit: submitForm
                )
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.top, 15)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Notice"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if showSuccess {
                        showLoginView = true // Navigate to login after success
                    }
                }
            )
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCropper) {
            if let image = formData.imageToCrop {
                NewTOCropViewSwiftUI(
                    image: image,
                    croppedImageData: Binding(
                        get: { formData.selectedImageData },
                        set: { data in
                            if formData.imageToCrop == formData.idImageToCrop {
                                formData.idImageData = data
                                formData.idImageToCrop = UIImage(data: data ?? Data())
                            } else {
                                formData.faceImageData = data
                                formData.faceImageToCrop = UIImage(data: data ?? Data())
                            }
                        }
                    ),
                    isPresented: $showCropper
                )
            }
        }
        .overlay(
            isLoading ? ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5) : nil
        )
        .overlay(
            CircleView()
                .animation(.easeInOut(duration: 0.35), value: showLoginView)
        )
        .disabled(isLoading)
        .fullScreenCover(isPresented: $showLoginView) {
            Login(showSignup: .constant(false)) // Assuming Login view takes a binding
        }
        .fullScreenCover(isPresented: $showSchoolRequest) {
            SchoolRequestView()
        }
        .onAppear(perform: verifyFirebaseSetup)
    }
    
    func CircleView() -> some View {
        Circle()
            .fill(.linearGradient(colors: [Color(UIColor(hex: "007AFF")), Color(UIColor(hex: "007AFF")).opacity(0.2)], startPoint: .top, endPoint: .bottom))
            .frame(width: 200, height: 200)
            .offset(x: -290, y: showLoginView ? -300 : -100)
            .blur(radius: 15)
            .hSpacing(.trailing)
            .vSpacing(.top)
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 1:
            WelcomeStep(showLoginView: $showLoginView)
        case 2:
            UserInformationStep(formData: $formData, showSchoolRequest: $showSchoolRequest)
        case 3:
            firstUserSurveySection(formData: $formData)
        case 4:
            ImagePickerStep(formData: $formData, showCropper: $showCropper)
        case 5:
            AccountSetupStep(formData: $formData)
        default:
            EmptyView()
        }
    }
    
    private func validateAndProceed() {
        guard validateCurrentStep() else { return }
        withAnimation(.easeInOut) {
            if currentStep < totalSteps {
                currentStep += 1
            }
        }
    }
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case 2:
            print(formData)
            guard !formData.firstName.isEmpty,
                  !formData.surName.isEmpty,
                  isValidEmail(formData.schoolEmail),
                  !formData.phoneNumber.isEmpty else {
                showAlert(message: "Please complete all required fields correctly.")
                return false
            }
        case 4:
            guard formData.idImageData != nil,
                  formData.faceImageData != nil else {
                showAlert(message: "Please upload and crop both your ID and face photo.")
                return false
            }
        case 5:
            guard !formData.password.isEmpty,
                  formData.password == formData.confirmPassword,
                  formData.password.count >= 8 else {
                showAlert(message: "Passwords must match and be at least 8 characters.")
                return false
            }
        default:
            return true
        }
        return true
    }
    
    private func submitForm() {
        isLoading = true
        Task {
            do {
                // Create user in Firebase Authentication
                let authResult = try await Auth.auth().createUser(
                    withEmail: formData.schoolEmail,
                    password: formData.password
                )
                let user = authResult.user
                
                // Send verification email
                try await user.sendEmailVerification()
                
                // Store user data in Firestore
                let db = Firestore.firestore()
                let userData: [String: Any] = [
                    "firstName": formData.firstName,
                    "lastName": formData.surName,
                    "schoolEmail": formData.schoolEmail.lowercased(),
                    "phoneNumber": formData.phoneNumber,
                    "otherSchool": formData.otherSchool,
                    "primaryTransportation": formData.primaryTransportation,
                    "ownsScooter": formData.ownsScooter,
                    "ownsSkateboard": formData.ownsSkateboard,
                    "ownsBike": formData.ownsBike,
                    "useCase": formData.useCase,
                    "acquisitionChannel": formData.acquisitionChannel,
                    "createdAt": Timestamp()
                ]
                try await db.collection("Users").document(user.uid).setData(userData)
                
                // Upload images to Firebase Storage
                try await uploadImages(userId: user.uid)
                
                // Show success message with email verification notice
                showSuccess(message: "Account created successfully! Please check your email (\(formData.schoolEmail)) to verify your account before logging in.")
            } catch {
                showAlert(message: "Error: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }
    
    private func uploadImages(userId: String) async throws {
        let storage = Storage.storage()
        
        if let idData = formData.idImageData {
            let idRef = storage.reference().child("users/\(userId)/id.jpg")
            _ = try await idRef.putDataAsync(idData, metadata: nil)
        }
        
        if let faceData = formData.faceImageData {
            let faceRef = storage.reference().child("users/\(userId)/face.jpg")
            _ = try await faceRef.putDataAsync(faceData, metadata: nil)
        }
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccess(message: String) {
        alertMessage = message
        showAlert = true
        showSuccess = true
        isLoading = false // Reset loading state on success
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email) && email.contains("@uci.edu")
    }
    
    private func verifyFirebaseSetup() {
        if FirebaseApp.app() == nil {
            showAlert(message: "Service unavailable. Please try again later.")
        }
    }
}

struct SignUpFormData {
    var schoolEmail: String = ""
    var otherSchool: String = ""
    var primaryTransportation: String = "Walking"
    var ownsScooter: Bool = false
    var ownsSkateboard: Bool = false
    var ownsBike: Bool = false
    var useCase: String = "Rent a Scooter"
    var acquisitionChannel: String = ""
    var idImageToCrop: UIImage? = nil
    var faceImageToCrop: UIImage? = nil
    var idImageData: Data? = nil
    var faceImageData: Data? = nil
    var firstName: String = ""
    var surName: String = ""
    var phoneNumber: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var selectedItems: [PhotosPickerItem] = []
    var selectedImageData: Data? = nil
    var imageToCrop: UIImage? = nil
}

struct ProgressHeader: View {
    let step: Int
    let total: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ForEach(1...total, id: \.self) { index in
                    Circle()
                        .frame(width: 8, height: 8)
                        .foregroundColor(index <= step ? .blue : .gray.opacity(0.3))
                }
            }
            Text("Step \(step) of \(total)")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct NavigationFooter: View {
    @Binding var currentStep: Int
    @Binding var showLoginView: Bool
    let totalSteps: Int
    let onNext: () -> Void
    let onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            if currentStep > 1 {
                Button("Back") {
                    currentStep -= 1
                }
                .buttonStyle(SecondButtonStyle())
            } else {
                HStack(spacing: 6) {
                    Text("Have an account?")
                        .foregroundStyle(.gray)
                    Button("Login") {
                        showLoginView = true
                    }
                    .fontWeight(.bold)
                    .tint(Color(UIColor(hex: "007AFF"))) // Adjusted to match your primary color
                }
                .padding(.horizontal, 15)
            }
            
            Spacer()
            
            Button(currentStep == totalSteps ? "Sign Up" : "Next") {
                currentStep == totalSteps ? onSubmit() : onNext()
            }
            .buttonStyle(FirstButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

struct WelcomeStep: View {
    @State private var isTitleVisible = false
    @State private var isContentVisible = false
    @State private var falseVar = false
    @Binding var showLoginView: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 32) {
                VStack(alignment: .center, spacing: 12) {
                    Text("Welcome to Scootal")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor(hex: "007AFF")))
                        .opacity(isTitleVisible ? 1 : 0)
                        .offset(y: isTitleVisible ? 0 : 20)
                        .animation(.easeInOut(duration: 0.8), value: isTitleVisible)
                    
                    Text("The communal sharing platform for e-scooters.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                        .opacity(isTitleVisible ? 1 : 0)
                        .offset(y: isTitleVisible ? 0 : 10)
                        .animation(.easeInOut(duration: 0.8).delay(0.2), value: isTitleVisible)
                }
                
                VStack(spacing: 24) {
                    InfoCard(
                        title: "What is Scootal?",
                        description: "Say goodbye to packed buses and endless walks. Scootal is your peer-to-peer scooter rental platform.",
                        icon: "scooter"
                    )
                    .opacity(isContentVisible ? 1 : 0)
                    .offset(y: isContentVisible ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: isContentVisible)
                    
                    InfoCard(
                        title: "How Does it Work?",
                        description: "It’s simple: students with scooters share them with those who need a ride. Rent one or list yours to earn.",
                        icon: "arrow.triangle.2.circlepath"
                    )
                    .opacity(isContentVisible ? 1 : 0)
                    .offset(y: isContentVisible ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: isContentVisible)
                    
                    InfoCard(
                        title: "Where Can You Scoot?",
                        description: "We’re live at UC Irvine. More universities are coming soon!",
                        icon: "map"
                    )
                    .opacity(isContentVisible ? 1 : 0)
                    .offset(y: isContentVisible ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: isContentVisible)
                }
                
                HStack {
                    Spacer()
                    Text("Press 'Next' to create your account!")
                        .font(.headline)
                        .foregroundColor(Color(UIColor(hex: "007AFF")))
                        .opacity(isContentVisible ? 1 : 0)
                        .scaleEffect(isContentVisible ? 1 : 0.9)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(1.0), value: isContentVisible)
                    Spacer()
                }
            }
            .padding()
        }
        .onAppear {
            isTitleVisible = true
            isContentVisible = true
        }
        .fullScreenCover(isPresented: $showLoginView) {
            Login(showSignup: $falseVar)
        }
    }
}

struct UserInformationStep: View {
    @Binding var formData: SignUpFormData
    @Binding var showSchoolRequest: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Tell us about yourself")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor(hex: "007AFF")))
            
            VStack(alignment: .leading, spacing: 20) {
                CustomTextField(placeholder: "First Name", text: $formData.firstName, icon: "person")
                CustomTextField(placeholder: "Last Name", text: $formData.surName, icon: "person")
                CustomTextField(placeholder: "School Email", text: $formData.schoolEmail, icon: "envelope", keyboardType: .emailAddress)
                iPhoneNumberField("Phone", text: $formData.phoneNumber)
                                    .flagHidden(false) // Display country flag
                                    .flagSelectable(true) // Allow country selection
                                    .font(.body)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 8).strokeBorder())
                                    .onChange(of: formData.phoneNumber) { newValue in
                                        formData.phoneNumber = formatPhoneNumber(newValue)
                                    }
            }
            VStack (alignment: .leading, spacing: 15){
                
                Text("Don't go to school at UC Irvine?")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor(hex: "secondary")).opacity(0.6))
                
                Button("Request Your School") {
                    showSchoolRequest.toggle()
                }
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(UIColor(hex: "primary")))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
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

struct firstUserSurveySection: View {
    @Binding var formData: SignUpFormData
    
    private let transportationModes = ["Walking", "Scootering", "Biking", "Skateboarding", "Public Transportation", "Driving"]
    private let useCases = ["Rent a Scooter", "Rent my Scooter", "Both"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Your Preferences")
                .font(.title2)
                .foregroundColor(Color(UIColor(hex: "007AFF")))
                .fontWeight(.bold)
            
            TransportationPicker(
                title: "Primary Transportation",
                selectedTransportationMode: $formData.primaryTransportation,
                transportationMode: transportationModes
            )
            
            TransportationPicker(
                title: "How will you use Scootal?",
                selectedTransportationMode: $formData.useCase,
                transportationMode: useCases
            )
            
            VStack(alignment: .leading, spacing: 20) {
                Text("How did you hear about Scootal?")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor(hex: "secondary")).opacity(0.85))
                CustomTextField(placeholder: "I heard about Scootal from...", text: $formData.acquisitionChannel, icon: "ear")
            }
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Do you own any of the following?")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(Color(UIColor(hex: "secondary")).opacity(0.85))
                
                OwnershipSelector(
                    options: [
                        ("An Electric Scooter", $formData.ownsScooter),
                        ("An Electric Skateboard", $formData.ownsSkateboard),
                        ("An Electric Bike", $formData.ownsBike)
                    ]
                )
            }
        }
    }
}

struct OwnershipSelector: View {
    let options: [(String, Binding<Bool>)]
    
    var body: some View {
        ForEach(options.indices, id: \.self) { index in
            OwnershipOption(
                item: options[index].0,
                isOwned: options[index].1
            )
        }
    }
}

struct OwnershipOption: View {
    let item: String
    @Binding var isOwned: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text(item)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: { isOwned = true }) {
                Text("Yes")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isOwned ? .white : Color(UIColor(hex: "007AFF")))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .background(isOwned ? Color(UIColor(hex: "007AFF")) : Color(.systemGray6))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { isOwned = false }) {
                Text("No")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(!isOwned ? .white : Color(UIColor(hex: "007AFF")))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .background(!isOwned ? Color(UIColor(hex: "007AFF")) : Color(.systemGray6))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

struct TransportationPicker: View {
    var title: String
    @Binding var selectedTransportationMode: String
    var transportationMode: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor(hex: "secondary")).opacity(0.85))
            Picker(selection: $selectedTransportationMode, label: Text(title)) {
                ForEach(transportationMode, id: \.self) { mode in
                    Text(mode)
                        .foregroundColor(Color(UIColor(hex: "007AFF")))
                        .bold()
                }
            }
            .pickerStyle(WheelPickerStyle())
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .frame(height: 165)
        }
    }
}

struct ImagePickerStep: View {
    @Binding var formData: SignUpFormData
    @Binding var showCropper: Bool
    @State private var idSelectedItems: [PhotosPickerItem] = []
    @State private var faceSelectedItems: [PhotosPickerItem] = []
    
    var body: some View {
        VStack(alignment: .center, spacing: 32) {
            Text("Verify Your Identity")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor(hex: "007AFF")))
            
            VStack(alignment: .center, spacing: 16) {
                Text("University-issued ID")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Upload and crop a clear photo of your student ID.")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                ImageUploadField(
                    image: $formData.idImageToCrop,
                    croppedImage: $formData.idImageData,
                    selectedItems: $idSelectedItems,
                    showCropper: $showCropper,
                    onSelect: { formData.imageToCrop = formData.idImageToCrop }
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            VStack(alignment: .center, spacing: 16) {
                Text("Face Photo")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Upload and crop a clear photo of your face.")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                ImageUploadField(
                    image: $formData.faceImageToCrop,
                    croppedImage: $formData.faceImageData,
                    selectedItems: $faceSelectedItems,
                    showCropper: $showCropper,
                    onSelect: { formData.imageToCrop = formData.faceImageToCrop }
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct ImageUploadField: View {
    @Binding var image: UIImage?
    @Binding var croppedImage: Data?
    @Binding var selectedItems: [PhotosPickerItem]
    @Binding var showCropper: Bool
    let onSelect: () -> Void
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: 1,
            matching: .images
        ) {
            ZStack {
                if let croppedImage = croppedImage, let uiImage = UIImage(data: croppedImage) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 350, height: 300)
                        .cornerRadius(8)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 32))
                        Text("Tap to Upload and Crop")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Color(UIColor(hex: "007AFF")))
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(UIColor(hex: "007AFF")), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
                }
            }
        }
        .onChange(of: selectedItems) { newItems in
            Task {
                if let item = newItems.first,
                   let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    image = uiImage
                    onSelect()
                    showCropper = true
                }
            }
        }
    }
}

struct AccountSetupStep: View {
    @Binding var formData: SignUpFormData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Create Account")
                .font(.title2)
                .foregroundColor(Color(UIColor(hex: "007AFF")))
                .fontWeight(.bold)
            
            CustomSecureField(placeholder: "Password", text: $formData.password)
            CustomSecureField(placeholder: "Confirm Password", text: $formData.confirmPassword)
            
            Text("Password must be at least 8 characters.")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct InfoCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(width: 350, height: 180)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textContentType(.none)
                .submitLabel(.next)
                .disableAutocorrection(true)
                .autocapitalization(.none)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundColor(.gray)
            SecureField(placeholder, text: $text)
                .textContentType(.password)
                .submitLabel(.next)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FirstButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 30)
            .background(Color(UIColor(hex: "007AFF"))) // Adjusted to match your primary color
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct SecondButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(Color(UIColor(hex: "8E8E93")))
            .padding(.vertical, 12)
            .padding(.horizontal, 30)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct HaveAccountStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(Color(UIColor(hex: "007AFF")))
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
            .background(Color.white)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct NewTOCropViewSwiftUI: UIViewControllerRepresentable {
    let image: UIImage
    @Binding var croppedImageData: Data?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> TOCropViewController {
        let cropViewController = TOCropViewController(image: image)
        cropViewController.delegate = context.coordinator
        cropViewController.aspectRatioPreset = .preset4x3
        cropViewController.aspectRatioLockEnabled = true
        cropViewController.resetAspectRatioEnabled = false
        cropViewController.rotateButtonsHidden = false
        cropViewController.resetButtonHidden = false
        return cropViewController
    }

    func updateUIViewController(_ uiViewController: TOCropViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, TOCropViewControllerDelegate {
        var parent: NewTOCropViewSwiftUI

        init(_ parent: NewTOCropViewSwiftUI) {
            self.parent = parent
        }

        func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with rect: CGRect, angle: NSInteger) {
            parent.croppedImageData = image.jpegData(compressionQuality: 0.4)
            parent.isPresented = false
        }

        func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
            parent.croppedImageData = nil
            parent.isPresented = false
        }
    }
}



#Preview {
    ScootalSignUp()
}
