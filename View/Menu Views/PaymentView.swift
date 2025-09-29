//
//  PaymentView.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-02-24.
//
import SwiftUI
import PassKit

struct PaymentView: View {
    @State private var selectedAmount = 2
    @State private var customAmount = ""
    @State private var selectedPaymentMethod: PaymentMethod = .applePay
    @State private var isProcessingPayment = false
    @State private var showingPaymentResult = false
    @State private var paymentSuccess = false
    @State private var paymentCoordinator: ApplePayCoordinator? // Store the coordinator
    
    let creditAmounts = [10, 20, 50, 100]
    
    enum PaymentMethod: String, CaseIterable {
        case applePay = "Apple Pay"
        case paypal = "PayPal"
        case stripe = "Credit Card"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Amount")
                        .font(.headline)
                        .foregroundColor(Color(UIColor(hex: "primary")))
                    
                    HStack {
                        ForEach(0..<4) { index in
                            CreditAmountButton(amount: creditAmounts[index], isSelected: selectedAmount == index) {
                                selectedAmount = index
                                customAmount = ""
                            }
                        }
                    }
                    
                    HStack {
                        Text("$")
                            .foregroundColor(Color(UIColor(hex: "primary")))
                        TextField("Custom Amount", text: $customAmount)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: customAmount) { _ in
                                selectedAmount = 4
                            }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Payment Method")
                        .font(.headline)
                        .foregroundColor(Color(UIColor(hex: "primary")))
                    
                    ForEach(PaymentMethod.allCases, id: \.self) { method in
                        PaymentMethodButton(method: method, isSelected: selectedPaymentMethod == method) {
                            selectedPaymentMethod = method
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
                
                Button(action: processPayment) {
                    Text("Add \(formattedAmount) Credits")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor(hex: "primary")))
                        .cornerRadius(15)
                }
                .disabled(isProcessingPayment)
                .opacity(isProcessingPayment ? 0.5 : 1)
            }
            .padding()
        }
        .alert(isPresented: $showingPaymentResult) {
            Alert(
                title: Text(paymentSuccess ? "Payment Successful" : "Payment Failed"),
                message: Text(paymentSuccess ? "Credits have been added to your account." : "There was an error processing your payment. Please try again."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    var formattedAmount: String {
        if selectedAmount == 4 {
            return "$\(customAmount)"
        } else {
            return "$\(creditAmounts[selectedAmount])"
        }
    }
    
    var paymentAmount: Decimal {
        if selectedAmount == 4, let custom = Decimal(string: customAmount), !customAmount.isEmpty {
            return custom
        }
        return Decimal(creditAmounts[selectedAmount])
    }
    
    func processPayment() {
        print("Process payment triggered with method: \(selectedPaymentMethod.rawValue)")
        isProcessingPayment = true
        
        switch selectedPaymentMethod {
        case .applePay:
            if PKPaymentAuthorizationController.canMakePayments() {
                print("Apple Pay is available")
                let request = PKPaymentRequest()
                request.merchantIdentifier = "merchant.com.Scootal.scootal" // Replace with your merchant ID
                request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
                request.merchantCapabilities = .capability3DS
                request.countryCode = "US"
                request.currencyCode = "USD"
                
                let paymentItem = PKPaymentSummaryItem(
                    label: "Credits Purchase",
                    amount: NSDecimalNumber(decimal: paymentAmount)
                )
                request.paymentSummaryItems = [paymentItem]
                
                let paymentController = PKPaymentAuthorizationController(paymentRequest: request)
                paymentCoordinator = ApplePayCoordinator(
                    didAuthorizePayment: { paymentSuccess in
                        print("Payment authorization result: \(paymentSuccess)")
                        self.isProcessingPayment = false
                        self.paymentSuccess = paymentSuccess
                        self.showingPaymentResult = true
                        self.paymentCoordinator = nil // Clean up
                    },
                    didFinish: {
                        print("Payment controller finished")
                        self.isProcessingPayment = false
                        self.paymentCoordinator = nil // Clean up
                    }
                )
                paymentController.delegate = paymentCoordinator
                print("Presenting payment controller")
                paymentController.present { success in
                    if !success {
                        print("Failed to present payment controller")
                        self.isProcessingPayment = false
                        self.paymentSuccess = false
                        self.showingPaymentResult = true
                    }
                }
            } else {
                print("Apple Pay not available on this device")
                isProcessingPayment = false
                paymentSuccess = false
                showingPaymentResult = true
            }
            
        case .paypal:
            print("Processing PayPal payment")
            simulatePayment()
            
        case .stripe:
            print("Processing Stripe payment")
            simulatePayment()
        }
    }
    
    private func simulatePayment() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isProcessingPayment = false
            paymentSuccess = Bool.random()
            showingPaymentResult = true
        }
    }
}

class ApplePayCoordinator: NSObject, PKPaymentAuthorizationControllerDelegate {
    private let completion: (Bool) -> Void
    private let onFinish: () -> Void
    
    init(didAuthorizePayment: @escaping (Bool) -> Void, didFinish: @escaping () -> Void) {
        self.completion = didAuthorizePayment
        self.onFinish = didFinish
        super.init()
    }
    
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                      didAuthorizePayment payment: PKPayment,
                                      handler: @escaping (PKPaymentAuthorizationResult) -> Void) {
        print("Did authorize payment called")
        
        // In a sandbox environment, assume success for testing
        let success = true // Simplified for testing; in production, validate payment.token
        let status: PKPaymentAuthorizationStatus = success ? .success : .failure
        
        var errors: [Error]?
        if !success {
            if #available(iOS 14.0, *) {
                let paymentError = PKPaymentError(.unknownError, userInfo: [NSLocalizedDescriptionKey: "Payment processing failed"])
                errors = [paymentError]
            } else {
                let error = NSError(
                    domain: PKPaymentErrorDomain,
                    code: PKPaymentError.unknownError.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Payment processing failed"]
                )
                errors = [error]
            }
        }
        
        let result = PKPaymentAuthorizationResult(status: status, errors: errors)
        handler(result)
        print("Handler called with status: \(status)")
        
        // Notify BookingView of the result
        self.completion(success)
        print("Completion called with success: \(success)")
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        print("Did finish called")
        controller.dismiss {
            print("Dismiss completed")
            self.onFinish()
        }
    }
}
    struct CreditAmountButton: View {
        let amount: Int
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text("$\(amount)")
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : Color(UIColor(hex: "primary")))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSelected ? Color(UIColor(hex: "primary")) : Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(UIColor(hex: "primary")), lineWidth: 2)
                    )
            }
        }
    }
    
    struct PaymentMethodButton: View {
        let method: PaymentView.PaymentMethod
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Image(systemName: paymentIcon(for: method))
                        .foregroundColor(isSelected ? .white : Color(UIColor(hex: "primary")))
                    Text(method.rawValue)
                        .foregroundColor(isSelected ? .white : Color(UIColor(hex: "primary")))
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(isSelected ? Color(UIColor(hex: "primary")) : Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(UIColor(hex: "primary")), lineWidth: 2)
                )
            }
        }
        
        func paymentIcon(for method: PaymentView.PaymentMethod) -> String {
            switch method {
            case .applePay:
                return "apple.logo"
            case .paypal:
                return "p.circle.fill"
            case .stripe:
                return "creditcard"
            }
        }
    }
    
    struct PaymentView_Previews: PreviewProvider {
        static var previews: some View {
            PaymentView()
        }
    }
