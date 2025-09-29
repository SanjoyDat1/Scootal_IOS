import SwiftUI
import TOCropViewController
import Firebase
import FirebaseAuth
import FirebaseStorage

struct AddScooterView: View {
    @State private var scooterName: String = ""
    @State private var scooterDescription: String = ""
    @State private var serialNumber: String = ""
    @State private var estimatedValue: String = ""
    @State private var sixHourPrice: String = ""
    @State private var fullDayPrice: String = ""
    @State private var topSpeed: String = ""
    @State private var location: String? = nil
    @State private var selectedImageData: Data? = nil
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showSuccess: Bool = false
    @State private var showCropper: Bool = false
    @State private var imageToCrop: UIImage? = nil
    @State private var currentStep: Int = 1
    @State private var showCamera: Bool = false // Added for camera
    
    // Additional fields
    @State private var isElectric: Bool = false
    @State private var brand: String = ""
    @State private var modelName: String = ""
    @State private var yearOfMake: String = ""
    @State private var range: String = ""
    @State private var damages: String = ""
    @State private var lateFee: String = ""
    @State private var restrictions: String = ""
    @State private var specialNotes: String = ""
    
    // Protection Plan fields
    @State private var protectionPlan: ProtectionPlan = .optOut
    @State private var understoodProtectionPlan: Bool = false
    
    enum ProtectionPlan: String, CaseIterable {
        case optOut = "Opt-Out"
        case basic = "Basic"
        case standard = "Standard"
        case premium = "Premium"
    }

    @Environment(\.dismiss) var dismiss

    let locations = [
        "Aldrich Park", "Anteater Recreation Center", "Anteatery - Mesa Court",
        "Brandywine - Middle Earth", "Flagpoles", "Langson Library",
        "Science Library", "Student Center"
    ]

    // Calculated minimum prices based on estimated value
    private var minSixHourPrice: Double {
        guard let value = Double(estimatedValue), !estimatedValue.isEmpty else { return 0.0 }
        return value * 0.01 // 1% of scooter cost
    }
    
    private var minFullDayPrice: Double {
        guard let value = Double(estimatedValue), !estimatedValue.isEmpty else { return 0.0 }
        return value * 0.02 // 2% of scooter cost
    }

    // Minimum rental prices based on protection plan contribution
    private var protectionPlanMinSixHourPrice: Double {
        switch protectionPlan {
        case .optOut: return minSixHourPrice
        case .basic: return 1.0
        case .standard: return 2.0
        case .premium: return 5.0
        }
    }
    
    private var protectionPlanMinFullDayPrice: Double {
        switch protectionPlan {
        case .optOut: return minFullDayPrice
        case .basic: return 2.0
        case .standard: return 4.0
        case .premium: return 10.0
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                progressBar
                ScrollView {
                    VStack(spacing: 25) {
                        switch currentStep {
                        case 1:
                            scooterBasicsSection
                        case 2:
                            scooterDetailsSection
                        case 3:
                            protectionPlanSection
                        case 4:
                            pricingSection
                        case 5:
                            performanceLocationSection
                        case 6:
                            additionalInfoSection
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                navigationButtons
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Info"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                    if showSuccess {
                        dismiss()
                    }
                })
            }
            .navigationBarItems(leading: dismissButton)
            .navigationBarTitle("List Your Scooter", displayMode: .inline)
            .sheet(isPresented: $showCropper, onDismiss: handleCropperDismiss) {
                if let image = imageToCrop {
                    TOCropViewSwiftUI(image: image, croppedImageData: $selectedImageData, isPresented: $showCropper)
                }
            }
            .sheet(isPresented: $showCamera) {
                NewImagePicker(sourceType: .camera, selectedImageData: $selectedImageData, imageToCrop: $imageToCrop, showCropper: $showCropper)
            }
            .onAppear(perform: verifyFirebaseSetup)
        }
    }

    // MARK: - UI Components

    private var progressBar: some View {
        ProgressBar(currentStep: currentStep, totalSteps: 6)
            .padding()
    }

    private var scooterBasicsSection: some View {
        VStack(spacing: 20) {
            imagePickerView
            Toggle("Is Electric Scooter", isOn: $isElectric)
            CustomInputField(title: "Scooter Name", text: $scooterName, placeholder: "e.g., Scootal Scooter")
            CustomInputField(title: "Brand", text: $brand, placeholder: "e.g., Scootal")
            CustomInputField(title: "Model Name", text: $modelName, placeholder: "e.g., First Generation")
            CustomInputField(title: "Year of Make", text: $yearOfMake, placeholder: "e.g., 2025", keyboardType: .numberPad)
        }
    }

    private var scooterDetailsSection: some View {
        VStack(spacing: 20) {
            CustomInputField(title: "Description", text: $scooterDescription, placeholder: "Describe your scooter")
            CustomInputField(title: "Serial Number", text: $serialNumber, placeholder: "Enter serial number")
            CustomInputField(title: "Estimated Value ($)", text: $estimatedValue, placeholder: "Max $500", keyboardType: .decimalPad)
            CustomInputField(title: "Range (approx. miles per charge)", text: $range, placeholder: "e.g., 15.5", keyboardType: .decimalPad)
        }
    }

    private var protectionPlanSection: some View {
        VStack(spacing: 20) {
            Text("Scootal Protection Plan (Optional)")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("The Scootal Protection Plan is an optional feature that allows you, the owner, to contribute a fixed amount per rental from your earnings. In exchange, Scootal will waive the renter’s liability for damages or loss/theft of your scooter during the rental period (6-hour or 24-hour) up to the specified limits, and Scootal will compensate you for the same amounts, subject to the terms below.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("• You select a plan (or opt-out).")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• You contribute a fixed amount per rental, deducted from your earnings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• Your rental price must be greater than your contribution amount.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• Scootal waives the renter’s liability for damages or loss/theft up to the plan’s limits for the duration of the rental.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("• Scootal compensates you for the same amounts, capped at the scooter’s estimated value.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 5)
            
            Text("NOTICE: The Scootal Protection Plan is not an insurance product and does not constitute insurance under California law (Cal. Ins. Code § 1631 et seq.). Scootal does not act as an insurer, does not transfer risk, and does not guarantee compensation. This plan is a contractual waiver of liability integrated into the rental agreement, whereby Scootal waives the renter’s liability for certain damages or loss/theft and agrees to compensate the owner as a service fee, subject to the terms herein. Scootal’s obligations are limited to the amounts specified in the selected plan, and Scootal assumes no liability beyond those amounts.")
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
            
            Picker("Protection Plan", selection: $protectionPlan) {
                ForEach(ProtectionPlan.allCases, id: \.self) { plan in
                    Text(plan.rawValue).tag(plan)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            VStack(alignment: .leading, spacing: 15) {
                switch protectionPlan {
                case .optOut:
                    Text("Opt-Out")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("You contribute $0 per rental. You receive the full rental price (e.g., $6 for a $6 rental). Scootal will not waive any renter liability for damages or loss/theft, and you will not receive any compensation from Scootal for such incidents. Renters remain contractually liable for all damages or loss/theft under the Terms of Service, but Scootal is not responsible for enforcing or collecting such amounts from renters.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Best for: Owners willing to assume all risks of damage or loss/theft.")
                        .font(.caption)
                        .foregroundColor(.gray)
                
                case .basic:
                    Text("Basic Plan")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("You contribute $1 (6-hour) or $2 (24-hour) per rental, deducted from your earnings (e.g., for a $6 rental, you receive $5 for 6-hour, $4 for 24-hour). Scootal waives renter liability for damages up to $30, and loss/theft up to $60. Scootal will compensate you for the same amounts, subject to the terms below.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Best for: Low-cost scooters ($100–$150) with minimal risk.")
                        .font(.caption)
                        .foregroundColor(.gray)
                
                case .standard:
                    Text("Standard Plan")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("You contribute $2 (6-hour) or $4 (24-hour) per rental, deducted from your earnings (e.g., for a $6 rental, you receive $3 for 6-hour, $1 for 24-hour). Scootal waives renter liability for damages up to $50, and loss/theft up to $110. Scootal will compensate you for the same amounts, subject to the terms below.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Best for: Mid-range scooters ($200–$300) needing moderate protection.")
                        .font(.caption)
                        .foregroundColor(.gray)
                
                case .premium:
                    Text("Premium Plan")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text("You contribute $5 (6-hour) or $10 (24-hour) per rental, deducted from your earnings (e.g., for a $10 rental, you receive $4 for 6-hour, $2 for 24-hour). Scootal waives renter liability for damages up to $80, and loss/theft up to $200. Scootal will compensate you for the same amounts, subject to the terms below.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Best for: Higher-value scooters ($300–$500) wanting better coverage.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 10)
            
            Toggle(isOn: $understoodProtectionPlan) {
                Text("I understand that the Scootal Protection Plan is not insurance, compensation is not guaranteed beyond the specified limits, and Scootal is not liable beyond those amounts.")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .padding(.top, 10)
        }
    }

    private var pricingSection: some View {
        VStack(spacing: 20) {
            Text("Set your rental prices (minimums based on scooter value: $\(String(format: "%.2f", minSixHourPrice))/6hrs, $\(String(format: "%.2f", minFullDayPrice))/day, and must exceed protection plan contribution: $\(String(format: "%.2f", protectionPlanMinSixHourPrice))/6hrs, $\(String(format: "%.2f", protectionPlanMinFullDayPrice))/day)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Six-Hour Price
            CustomInputField(title: "Six-Hour Price ($)", text: $sixHourPrice, placeholder: "e.g., $\(String(format: "%.2f", max(minSixHourPrice, protectionPlanMinSixHourPrice)))", keyboardType: .decimalPad)
            
            // Full-Day Price
            CustomInputField(title: "Full-Day Price ($)", text: $fullDayPrice, placeholder: "e.g., $\(String(format: "%.2f", max(minFullDayPrice, protectionPlanMinFullDayPrice)))", keyboardType: .decimalPad)
            
            // Late Fee with Info Icon
            HStack {
                CustomInputField(title: "Late Fee ($/15 min)", text: $lateFee, placeholder: "e.g., $1.25", keyboardType: .decimalPad)
                Button(action: showLateFeeInfo) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                }
            }
            
            // Earnings Breakdown
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Earnings After Protection Plan Contribution:")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                let sixHour = Double(sixHourPrice) ?? 0.0
                let fullDay = Double(fullDayPrice) ?? 0.0
                
                switch protectionPlan {
                case .optOut:
                    Text("Opt-Out: You keep 100%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• 6-Hour: $\(String(format: "%.2f", sixHour))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• Full-Day: $\(String(format: "%.2f", fullDay))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .basic:
                    let sixHourOwner = sixHour - 1.0
                    let fullDayOwner = fullDay - 2.0
                    Text("Basic Plan: You contribute $1 (6-hour) or $2 (24-hour)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• 6-Hour: $\(String(format: "%.2f", sixHourOwner))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• Full-Day: $\(String(format: "%.2f", fullDayOwner))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .standard:
                    let sixHourOwner = sixHour - 2.0
                    let fullDayOwner = fullDay - 4.0
                    Text("Standard Plan: You contribute $2 (6-hour) or $4 (24-hour)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• 6-Hour: $\(String(format: "%.2f", sixHourOwner))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• Full-Day: $\(String(format: "%.2f", fullDayOwner))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .premium:
                    let sixHourOwner = sixHour - 5.0
                    let fullDayOwner = fullDay - 10.0
                    Text("Premium Plan: You contribute $5 (6-hour) or $10 (24-hour)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• 6-Hour: $\(String(format: "%.2f", sixHourOwner))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• Full-Day: $\(String(format: "%.2f", fullDayOwner))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 10)
        }
    }

    private func showLateFeeInfo() {
        alertMessage = """
        Late Fee Explanation:
        The late fee is an additional charge applied to renters who return your scooter past the agreed rental period. It is assessed at the rate you set, charged per 15-minute increment of lateness. For example, if you set a late fee of $1.25 per 15 minutes and a renter is 30 minutes late, they will be charged $2.50. This fee is collected by Scootal and paid directly to you, the owner, to compensate for the inconvenience and potential loss of rental opportunities.
        """
        showAlert = true
    }

    private var performanceLocationSection: some View {
        VStack(spacing: 20) {
            CustomInputField(title: "Top Speed (mph)", text: $topSpeed, placeholder: "Max 45 mph", keyboardType: .decimalPad)
            LocationPicker(title: "Pickup Location", selectedLocation: $location, locations: locations)
        }
    }

    private var additionalInfoSection: some View {
        VStack(spacing: 20) {
            CustomTextEditor(title: "Damages", text: $damages, placeholder: "Describe any existing damage or wear")
            CustomTextEditor(title: "Restrictions", text: $restrictions, placeholder: "List any usage restrictions")
            CustomTextEditor(title: "Special Notes", text: $specialNotes, placeholder: "Any additional information")
        }
    }

    private var imagePickerView: some View {
        Button(action: {
            showCamera = true
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.white))
                    .frame(height: 225)
                    .frame(width: 225)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color(UIColor(hex: "primary")), lineWidth: 2)
                    )
                if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(height: 225)
                        .frame(width: 225)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color(UIColor(hex: "primary")), lineWidth: 2)
                        )
                } else {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Take Scooter Photo")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var navigationButtons: some View {
        HStack {
            if currentStep > 1 {
                Button("Back") {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            Spacer()
            if currentStep < 6 {
                Button("Next") {
                    if validateCurrentStep() {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button(action: validateAndAddScooter) {
                    Text(isLoading ? "Listing..." : "List Your Scooter")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isLoading)
            }
        }
        .padding()
    }

    private var dismissButton: some View {
        Button("Cancel") {
            dismiss()
        }
    }

    // MARK: - Logic

    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case 1:
            if !isElectric {
                alertMessage = "Only electric scooters are allowed."
                showAlert = true
                return false
            }
            if selectedImageData == nil || scooterName.isEmpty || brand.isEmpty || modelName.isEmpty || yearOfMake.isEmpty {
                alertMessage = "Please fill in all fields and take a photo."
                showAlert = true
                return false
            }
            if Int(yearOfMake) ?? 0 < 1900 || Int(yearOfMake) ?? 0 > Calendar.current.component(.year, from: Date()) {
                alertMessage = "Please give a valid year."
                showAlert = true
                return false
            }
        case 2:
            if scooterDescription.isEmpty || serialNumber.isEmpty || estimatedValue.isEmpty || range.isEmpty {
                alertMessage = "Please fill in all fields."
                showAlert = true
                return false
            }
            if Double(estimatedValue) == nil || Double(estimatedValue)! > 500 {
                alertMessage = "Estimated value must be a number not exceeding $500."
                showAlert = true
                return false
            }
        case 3:
            if !understoodProtectionPlan {
                alertMessage = "Please confirm you understand the Scootal Protection Plan terms by checking the box."
                showAlert = true
                return false
            }
        case 4:
            if sixHourPrice.isEmpty || fullDayPrice.isEmpty || lateFee.isEmpty {
                alertMessage = "Please enter all pricing information."
                showAlert = true
                return false
            }
            if let sixHour = Double(sixHourPrice), let fullDay = Double(fullDayPrice), let late = Double(lateFee) {
                if sixHour < max(minSixHourPrice, protectionPlanMinSixHourPrice) || fullDay < max(minFullDayPrice, protectionPlanMinFullDayPrice) {
                    alertMessage = "Prices must meet minimums: $\(String(format: "%.2f", max(minSixHourPrice, protectionPlanMinSixHourPrice)))/6hrs, $\(String(format: "%.2f", max(minFullDayPrice, protectionPlanMinFullDayPrice)))/day."
                    showAlert = true
                    return false
                }
                if sixHour > 50 || fullDay > 50 {
                    alertMessage = "Prices must not exceed $50."
                    showAlert = true
                    return false
                }
            } else {
                alertMessage = "Please enter valid prices."
                showAlert = true
                return false
            }
        case 5:
            if topSpeed.isEmpty || location == nil {
                alertMessage = "Please enter top speed and select a location."
                showAlert = true
                return false
            }
            if Double(topSpeed) == nil || Double(topSpeed)! > 45 {
                alertMessage = "Top speed must be a number not exceeding 45 mph."
                showAlert = true
                return false
            }
        case 6:
            if damages.isEmpty {
                alertMessage = "Please provide a damage report, even if there's no damage."
                showAlert = true
                return false
            }
        default:
            return true
        }
        return true
    }

    private func validateAndAddScooter() {
        if !validateCurrentStep() {
            return
        }
        if Auth.auth().currentUser == nil {
            alertMessage = "Please log in to upload a scooter."
            showAlert = true
            return
        }
        addScooter()
    }

    private func addScooter() {
        isLoading = true
        guard let imageData = selectedImageData else {
            alertMessage = "No cropped image data available."
            showAlert = true
            isLoading = false
            return
        }
        guard let originalImage = UIImage(data: imageData),
              let resizedImageData = resizeImageToSquare(image: originalImage, sideLength: 400, compressionQuality: 0.5) else {
            alertMessage = "Failed to process image for upload."
            showAlert = true
            isLoading = false
            return
        }

        let imageName = UUID().uuidString
        let storageRef = Storage.storage().reference().child("scooter_images/\(imageName).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(resizedImageData, metadata: metadata) { (metadata, error) in
            if let error = error {
                self.alertMessage = "Failed to upload image: \(error.localizedDescription)"
                self.showAlert = true
                self.isLoading = false
                return
            }
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    self.alertMessage = "Failed to retrieve image URL: \(error.localizedDescription)"
                    self.showAlert = true
                    self.isLoading = false
                    return
                }
                guard let imageURL = url?.absoluteString else {
                    self.alertMessage = "Failed to get image URL."
                    self.showAlert = true
                    self.isLoading = false
                    return
                }

                let scooterData: [String: Any] = [
                    "confirmationCode": "",
                    "scooterName": self.scooterName,
                    "brand": self.brand,
                    "modelName": self.modelName,
                    "yearOfMake": self.yearOfMake,
                    "serialNumber": self.serialNumber,
                    "description": self.scooterDescription,
                    "estimatedValue": Double(self.estimatedValue) ?? 0.0,
                    "range": Double(self.range) ?? 0.0,
                    "sixHourPrice": Double(self.sixHourPrice) ?? 0.0,
                    "fullDayPrice": Double(self.fullDayPrice) ?? 0.0,
                    "lateFee": Double(self.lateFee) ?? 0.0,
                    "topSpeed": Double(self.topSpeed) ?? 0.0,
                    "location": self.location!,
                    "damages": self.damages,
                    "restrictions": self.restrictions,
                    "specialNotes": self.specialNotes,
                    "isElectric": self.isElectric,
                    "isAvailable": false,
                    "isBooked": false,
                    "activeBooking": false,
                    "isFeatured": false,
                    "ownerID": Auth.auth().currentUser?.uid ?? "",
                    "imageURL": imageURL,
                    "protectionPlan": self.protectionPlan.rawValue,
                    "timestamp": Timestamp()
                ]

                Firestore.firestore().collection("Scooters").addDocument(data: scooterData) { error in
                    if let error = error {
                        self.alertMessage = "Error saving scooter data: \(error.localizedDescription)"
                        self.showAlert = true
                    } else {
                        self.alertMessage = "Scooter listed successfully!"
                        self.showAlert = true
                        self.showSuccess = true
                    }
                    self.isLoading = false
                }
            }
        }
    }

    private func handleCropperDismiss() {
        if selectedImageData == nil {
            selectedImageData = nil
        } else if let image = UIImage(data: selectedImageData ?? Data()), image.size.width != image.size.height {
            alertMessage = "The cropped image must be a square. Please crop again."
            showAlert = true
            selectedImageData = nil
        }
    }

    private func verifyFirebaseSetup() {
        if FirebaseApp.app() == nil || Storage.storage() == nil {
            alertMessage = "Firebase is not initialized. Please check your setup."
            showAlert = true
        }
    }

    private func resizeImageToSquare(image: UIImage, sideLength: CGFloat, compressionQuality: CGFloat) -> Data? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: sideLength, height: sideLength))
        let resizedImage = renderer.image { _ in
            let scale = max(image.size.width / sideLength, image.size.height / sideLength)
            let newWidth = image.size.width / scale
            let newHeight = image.size.height / scale
            let originX = (sideLength - newWidth) / 2
            let originY = (sideLength - newHeight) / 2
            image.draw(in: CGRect(x: originX, y: originY, width: newWidth, height: newHeight))
        }
        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }
}

// MARK: - ImagePicker for Camera

struct NewImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImageData: Data?
    @Binding var imageToCrop: UIImage?
    @Binding var showCropper: Bool
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: NewImagePicker

        init(_ parent: NewImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.imageToCrop = image
                parent.showCropper = true
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Supporting Views and Styles

struct CustomInputField: View {
    var title: String
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            TextField(placeholder, text: $text)
                .padding(10)
                .background(Color.white)
                .cornerRadius(8)
                .keyboardType(keyboardType)
                .submitLabel(.done)
        }
    }
}

struct CustomTextEditor: View {
    var title: String
    @Binding var text: String
    var placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            TextEditor(text: $text)
                .frame(height: 100)
                .padding(5)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if text.isEmpty {
                            Text(placeholder)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                        }
                    }
                )
        }
    }
}

struct LocationPicker: View {
    var title: String
    @Binding var selectedLocation: String?
    let locations: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            Picker(selection: $selectedLocation, label: Text(selectedLocation ?? "Select location")) {
                Text("Select location").tag(nil as String?)
                ForEach(locations, id: \.self) { location in
                    Text(location).tag(location as String?)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(Color.white)
            .cornerRadius(8)
        }
    }
}

struct ProgressBar: View {
    var currentStep: Int
    var totalSteps: Int
    
    var body: some View {
        HStack {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(step < currentStep ? Color(UIColor(hex: "primary")) : Color.gray)
            }
        }
    }
}

struct TOCropViewSwiftUI: UIViewControllerRepresentable {
    let image: UIImage
    @Binding var croppedImageData: Data?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> TOCropViewController {
        let cropViewController = TOCropViewController(image: image)
        cropViewController.delegate = context.coordinator
        cropViewController.aspectRatioPreset = .presetSquare
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
        var parent: TOCropViewSwiftUI

        init(_ parent: TOCropViewSwiftUI) {
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

struct AddScooterView_Previews: PreviewProvider {
    static var previews: some View {
        AddScooterView()
    }
}
