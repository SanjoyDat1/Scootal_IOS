//
//  ScooterPickupView.swift
//  Scootal
//
//  Created by Sanjoy Datta on 2025-03-16.
//
import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct ScooterPickupView: View {
    @State private var currentStep: Int = 0
    @State private var imageData: [Data?] = Array(repeating: nil, count: 5)
    @State private var damageImages: [DamageEntry] = []
    @State private var showCamera: Bool = false
    @State private var showCropper: Bool = false
    @State private var imageToCrop: UIImage? = nil
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isSubmitting: Bool = false
    @State private var currentDamageIndex: Int? = nil // Track which damage entry we're editing
    
    @State private var isOwner: Bool = true // Boolean to check if the user is the owner or renter

    @Environment(\.dismiss) var dismiss

    private let photoPrompts = ["Front", "Rear", "Handlebars", "Front Tire", "Rear Tire"]
    private let photoGuides = [
        "Capture a straight-on shot of the scooter's front",
        "Take a direct view of the scooter's rear",
        "Photograph a close-up of the handlebars and controls",
        "Get a clear shot of the front tire",
        "Take a detailed view of the rear tire"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor", bundle: nil)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Header
                    VStack(spacing: 0) {
                        ProgressView(value: Float(currentStep + 1), total: 6)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .padding(.horizontal)
                        
                        Text(currentStep < 5 ? "Step \(currentStep + 1) of 5" : "Damage Report")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .padding(.top)
                    
                    if currentStep < 5 {
                        photoCaptureView
                    } else {
                        damageReportView
                    }
                }
                .navigationTitle("Scooter Check-Out")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(
                imageData: currentStep < 5 ? $imageData[currentStep] :
                    (currentDamageIndex != nil ? $damageImages[currentDamageIndex!].imageData : .constant(nil)),
                showCamera: $showCamera,
                imageToCrop: $imageToCrop,
                showCropper: $showCropper
            )
        }
        .sheet(isPresented: $showCropper, onDismiss: handleCropperDismiss) {
            if let image = imageToCrop {
                TOCropViewSwiftUI(
                    image: image,
                    croppedImageData: currentStep < 5 ? $imageData[currentStep] :
                        (currentDamageIndex != nil ? $damageImages[currentDamageIndex!].imageData : .constant(nil)),
                    isPresented: $showCropper
                )
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Notice"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    // Photo Capture View
    private var photoCaptureView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instruction
                VStack(spacing: 8) {
                    Text(photoPrompts[currentStep])
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text(photoGuides[currentStep])
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Image Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 400)
                    
                    if let data = imageData[currentStep], let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                
                // Controls
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        OutlinedButton(title: "Previous", action: { withAnimation { currentStep -= 1 } })
                    }
                    
                    PrimaryButton(
                        title: imageData[currentStep] == nil ? "Capture Photo" : "Retake",
                        action: { showCamera = true },
                        isPrimary: imageData[currentStep] == nil
                    )
                    
                    if imageData[currentStep] != nil {
                        PrimaryButton(
                            title: currentStep < 4 ? "Next" : "Continue",
                            action: { withAnimation { currentStep += 1 } }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
    
    // Damage Report View
    private var damageReportView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Report Any Damage (Optional)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .padding(.top)
                
                Text("Add up to 3 photos of any visible damage")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                
                ForEach(damageImages.indices, id: \.self) { index in
                    DamageEntryView(
                        entry: $damageImages[index],
                        onRetake: {
                            currentDamageIndex = index
                            showCamera = true
                        }
                    )
                }
                
                if damageImages.count < 3 {
                    PrimaryButton(
                        title: "Add Damage Photo",
                        action: {
                            damageImages.append(DamageEntry())
                            currentDamageIndex = damageImages.count - 1
                            showCamera = true
                        },
                        isPrimary: false
                    )
                }
                
                PrimaryButton(
                    title: isSubmitting ? "Submitting..." : "Submit Check-Out",
                    action: submitPhotos,
                    isEnabled: !isSubmitting
                )
            }
            .padding()
        }
    }
    
    // MARK: - Logic
    
    private func handleCropperDismiss() {
        if currentStep < 5, let data = imageData[currentStep], let image = UIImage(data: data) {
            if image.size.width != image.size.height {
                alertMessage = "Please crop the image to a square."
                showAlert = true
                imageData[currentStep] = nil
            }
        }
        currentDamageIndex = nil // Reset after cropping
    }
    
    private func submitPhotos() {
        guard imageData.allSatisfy({ $0 != nil }) else {
            alertMessage = "Please capture all required photos."
            showAlert = true
            return
        }
        
        isSubmitting = true
        // Submit photos to Firebase
        uploadPhotosToFirebase()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            alertMessage = "Check-Out completed successfully!"
            showAlert = true
            dismiss()
        }
    }
    
    // Upload photos to Firebase Storage and Firestore
    private func uploadPhotosToFirebase() {
        // Create a reference to Firebase Storage
        let storageRef = Storage.storage().reference().child("scooter_photos/\(UUID().uuidString)")
        
        // Upload each photo
        for (index, data) in imageData.enumerated() {
            guard let data = data else { continue }
            
            let photoRef = storageRef.child("photo_\(index).jpg")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            // Upload data to Firebase
            photoRef.putData(data, metadata: metadata) { (metadata, error) in
                if let error = error {
                    print("Error uploading photo: \(error.localizedDescription)")
                } else {
                    print("Photo uploaded successfully!")
                    // Optionally store photo URL or metadata in Firestore
                    savePhotoMetadataToFirestore(photoRef)
                }
            }
        }
    }
    
    private func savePhotoMetadataToFirestore(_ photoRef: StorageReference) {
        let db = Firestore.firestore()
        let photoData: [String: Any] = [
            "url": photoRef.fullPath,
            "isOwner": isOwner, // Store the user role
            "timestamp": Timestamp(date: Date())
        ]
        
        // Add metadata to Firestore
        db.collection("scooter_photos").addDocument(data: photoData) { error in
            if let error = error {
                print("Error saving photo metadata: \(error.localizedDescription)")
            } else {
                print("Photo metadata saved successfully!")
            }
        }
    }
}


// Damage Entry Model
struct DamageEntry: Identifiable {
    let id = UUID()
    var imageData: Data? = nil
    var description: String = ""
}

// Damage Entry View
struct DamageEntryView: View {
    @Binding var entry: DamageEntry
    let onRetake: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            if let data = entry.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            TextField("Describe the damage", text: $entry.description)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            PrimaryButton(
                title: "Retake Photo",
                action: onRetake,
                isPrimary: false
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Custom Buttons
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isPrimary: Bool = true
    var isEnabled: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(isPrimary ? .white : .blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isPrimary ? Color.blue : Color.clear)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: isPrimary ? 0 : 2)
                )
        }
        .disabled(!isEnabled)
    }
}

struct OutlinedButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.clear)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 2)
                )
        }
    }
}

// Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Binding var showCamera: Bool
    @Binding var imageToCrop: UIImage?
    @Binding var showCropper: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.imageToCrop = image
                parent.showCropper = true
            }
            parent.showCamera = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.showCamera = false
        }
    }
}

// Preview
struct ScooterPickupView_Previews: PreviewProvider {
    static var previews: some View {
        ScooterPickupView()
    }
}
