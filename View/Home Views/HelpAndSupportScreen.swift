//
//  HelpScreen.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-01-17.
//

import SwiftUI
import FirebaseAuth

struct HelpAndSupportScreen: View {
    @State private var bookingId: String?
    @State private var currentStep: Int = 1
    @State private var selectedCategory: String? = nil
    @State private var selectedIssue: String? = nil
    @State private var issueDetails: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var returnView = false
    @State private var showConfirmation = false
    @Environment(\.presentationMode) private var presentationMode // To handle cancel action

    var body: some View {
        NavigationView {
            VStack {
                // Progress Indicator
                ProgressView(value: Double(currentStep), total: 3)
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(UIColor(hex: "primary"))))
                    .padding(.vertical)

                // Display different steps
                if currentStep == 1 {
                    issueCategoryStep
                } else if currentStep == 2 {
                    if selectedCategory == "Other" {
                        issueDetailsStep
                    } else {
                        issueSelectionStep
                    }
                } else if currentStep == 3 {
                    issueDetailsStep
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Help & Support")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep > 1 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(Color(UIColor(hex: "primary")))
                    } else {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(Color(UIColor(hex: "primary")))
                    }
                }
            }
            .alert(isPresented: $showConfirmation) {
                Alert(
                    title: Text("Issue Submitted"),
                    message: Text("Thank you for your report! We’ll get back to you soon."),
                    dismissButton: .default(Text("OK")) {
                        returnView = true
                    }
                )
            }
            .fullScreenCover(isPresented: $returnView) {
                ScooterListView()
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onAppear {
                UITextField.appearance().clearButtonMode = .whileEditing
            }
        }
        .accentColor(Color(UIColor(hex: "accent")))
    }

    // Step 1: Select Category
    var issueCategoryStep: some View {
        VStack(alignment: .leading) {
            Text("What do you need help with?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor(hex: "primary")))

            ScrollView {
                VStack(spacing: 15) {
                    categoryButton("Scooter Condition")
                    categoryButton("Billing & Payments")
                    categoryButton("Rental Issues")
                    categoryButton("Other")
                }
            }
        }
    }

    // Step 2: Select Specific Issue
    var issueSelectionStep: some View {
        VStack(alignment: .leading) {
            Text("What’s the specific issue?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor(hex: "primary")))

            ScrollView {
                VStack(spacing: 15) {
                    if selectedCategory == "Scooter Condition" {
                        issueButton("The scooter won't start")
                        issueButton("The scooter is slower than expected")
                        issueButton("The scooter has poor brakes")
                        issueButton("Other")
                    } else if selectedCategory == "Billing & Payments" {
                        issueButton("I was charged incorrectly")
                        issueButton("I didn’t receive my refund")
                        issueButton("Payment failed")
                        issueButton("Other")
                    } else if selectedCategory == "Rental Issues" {
                        issueButton("The scooter wasn’t where it should be")
                        issueButton("The owner didn’t release the scooter")
                        issueButton("I had trouble returning the scooter")
                        issueButton("Other")
                    }
                }
            }
        }
    }

    // Step 3: Provide Details
    var issueDetailsStep: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Tell us more about the issue")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor(hex: "primary")))

            TextField("Describe your problem here...", text: $issueDetails)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom)

            // Image Upload Section
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .cornerRadius(10)
                    .padding(.bottom)
            } else {
                Button(action: {
                    showImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Add an image (optional)")
                            .font(.headline)
                    }
                    .foregroundColor(Color(UIColor(hex: "secondary")))
                    .padding()
                    .background(Color(UIColor(hex: "primary")).opacity(0.1))
                    .cornerRadius(10)
                }
            }

            // Submit Button
            Button(action: {
                print("Submit button tapped")
                print("Details: \(issueDetails)")
                if selectedImage != nil {
                    print("Image selected")
                }
                sendReport()
                showConfirmation = true
                resetForm()
            }) {
                Text("Submit")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor(hex: "primary")))
                    .cornerRadius(10)
            }
            .padding(.top)
        }
    }

    // Reusable UI Components
    private func categoryButton(_ title: String) -> some View {
        Button(action: {
            selectedCategory = title
            withAnimation {
                currentStep = title == "Other" ? 2 : 2
            }
        }) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: selectedCategory == title ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(Color(UIColor(hex: "accent")))
            }
            .padding()
            .background(Color(UIColor(hex: "primary")).opacity(0.1))
            .cornerRadius(10)
        }
    }

    private func issueButton(_ title: String) -> some View {
        Button(action: {
            selectedIssue = title
            withAnimation {
                currentStep = 3
                setIssueFormBlank()
            }
        }) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: selectedIssue == title ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.orange)
            }
            .padding()
            .background(Color(UIColor(hex: "primary")).opacity(0.1))
            .cornerRadius(10)
        }
    }

    // Reset Form
    private func resetForm() {
        selectedCategory = nil
        selectedIssue = nil
        issueDetails = ""
        selectedImage = nil
        currentStep = 1
    }
    
    private func setIssueFormBlank() {
        issueDetails = ""
        selectedImage = nil
    }

    // Simulated Report Sending
    private func sendReport() {
        print("Issue Submitted:")
        print("Category: \(selectedCategory ?? "None")")
        print("Issue: \(selectedIssue ?? "None")")
        print("Details: \(issueDetails)")
        print("Image Attached: \(selectedImage != nil)")
    }
}

// Image Picker Component
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Preview
struct HelpAndSupportScreen_Previews: PreviewProvider {
    static var previews: some View {
        HelpAndSupportScreen()
    }
}
