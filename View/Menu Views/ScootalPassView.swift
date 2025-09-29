//
//  ScootalPassView.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-02-24.
//
import SwiftUI
import StoreKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

// MARK: - StoreKit Manager Class
class StoreKitManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver, SKRequestDelegate, ObservableObject {
    private var products: [SKProduct] = []
    private var purchaseCompletion: ((Bool, String?) -> Void)?
    private var productsCompletion: (([SKProduct]) -> Void)?
    private var errorHandler: ((String) -> Void)?
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    func fetchProducts(productIdentifiers: Set<String>, completion: @escaping ([SKProduct]) -> Void, errorHandler: @escaping (String) -> Void) {
        print("Fetching products with identifiers: \(productIdentifiers)")
        self.productsCompletion = completion
        self.errorHandler = errorHandler
        let request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
    }
    
    func purchaseProduct(_ product: SKProduct, completion: @escaping (Bool, String?) -> Void) {
        print("Purchasing product: \(product.productIdentifier)")
        self.purchaseCompletion = completion
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    // MARK: - SKProductsRequestDelegate
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            let products = response.products
            print("Received products: \(products.map { $0.productIdentifier })")
            if products.isEmpty {
                print("No products received. Invalid product identifiers: \(response.invalidProductIdentifiers)")
            }
            self.products = products
            self.productsCompletion?(products)
        }
    }
    
    // MARK: - SKRequestDelegate
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("Failed to fetch products: \(error.localizedDescription)")
            self.errorHandler?("Failed to load products: \(error.localizedDescription)")
        }
    }
    
    // MARK: - SKPaymentTransactionObserver
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                print("Purchase successful: \(transaction.payment.productIdentifier)")
                self.purchaseCompletion?(true, nil)
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                print("Purchase failed: \(transaction.error?.localizedDescription ?? "Unknown error")")
                self.purchaseCompletion?(false, transaction.error?.localizedDescription ?? "Unknown error")
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                print("Transaction restored: \(transaction.payment.productIdentifier)")
            case .deferred:
                print("Transaction deferred: \(transaction.payment.productIdentifier)")
            case .purchasing:
                print("Transaction in progress: \(transaction.payment.productIdentifier)")
            @unknown default:
                break
            }
        }
    }
}

struct ScootalPassView: View {
    @StateObject private var storeKitManager = StoreKitManager()
    @State private var selectedPassType = 0
    @State private var showListScooterSheet = false
    @State private var products: [SKProduct] = [] // StoreKit products
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var userSubscription: SubscriptionStatus? // User's current subscription
    @State private var currentUser: User? // Track the current user
    
    let passTypes = ["Monthly", "Annual"]
    let passColors: [Color] = [.blue, .purple]
    let productIdentifiers = ["com.eympa.Eympa.scootalpass.monthly", "com.eympa.Eympa.scootalpass.annual"]
    
    private let db = Firestore.firestore()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Pass type selector
                Picker("Pass Type", selection: $selectedPassType) {
                    ForEach(0..<passTypes.count) { index in
                        Text(passTypes[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .disabled(isPurchasing || isSubscribedToSelectedPass)

                // Pass card
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(passColors[selectedPassType])
                        .frame(height: 200)
                        .shadow(radius: 10)
                    
                    VStack {
                        Text(passTypes[selectedPassType])
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("No Unlock Fee")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(passPrice)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, 5)
                        
                        if isSubscribedToSelectedPass {
                            Text("Active")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 5)
                        }
                    }
                }
                .padding(.horizontal)

                // Benefits
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pass Benefits:")
                        .font(.headline)
                    
                    BenefitRow(icon: "speedometer", text: "Priority access to scooters")
                    BenefitRow(icon: "dollarsign.circle", text: "No unlock fee on all rides")
                    BenefitRow(icon: "person.2.fill", text: "Bring a friend for free once a month")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)

                // Buy pass button
                Button(action: {
                    purchaseSelectedPass()
                }) {
                    Text(isSubscribedToSelectedPass ? "Subscribed" : "Get Your Pass")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isSubscribedToSelectedPass ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(isPurchasing || isSubscribedToSelectedPass || products.isEmpty)
                .padding(.horizontal)

                // Error message
                if let error = purchaseError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.horizontal)
                }

                // List your scooter section
                VStack(spacing: 10) {
                    Text("Got a scooter? Earn while you learn!")
                        .font(.headline)
                    
                    Button(action: {
                        showListScooterSheet = true
                    }) {
                        Text("List Your Scooter")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onAppear {
            setupAuthListener()
            fetchProducts()
        }
        .sheet(isPresented: $showListScooterSheet) {
            AddScooterView() // Assuming this exists elsewhere
        }
    }
    
    var passPrice: String {
        if products.isEmpty {
            switch selectedPassType {
            case 0: return "$2.99/month"
            case 1: return "$29.99/year"
            default: return ""
            }
        } else {
            let product = products[selectedPassType]
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceLocale
            let priceString = formatter.string(from: product.price) ?? "\(product.price)"
            return "\(priceString)/\(passTypes[selectedPassType].lowercased())"
        }
    }
    
    var isSubscribedToSelectedPass: Bool {
        guard let subscription = userSubscription else { return false }
        return subscription.productId == productIdentifiers[selectedPassType] && subscription.isActive
    }

    // Set up Firebase Auth state listener
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { auth, user in
            print("Auth state changed. User: \(user?.uid ?? "nil")")
            self.currentUser = user
            if user != nil {
                fetchUserSubscription()
            } else {
                print("No user signed in.")
                self.userSubscription = nil
            }
        }
    }

    // Fetch subscription products from App Store
    private func fetchProducts() {
        storeKitManager.fetchProducts(productIdentifiers: Set(productIdentifiers)) { products in
            self.products = products
            if products.isEmpty {
                self.purchaseError = "No products available. Please try again later."
            }
        } errorHandler: { error in
            self.purchaseError = error
            self.isPurchasing = false
        }
    }

    // Purchase the selected pass
    private func purchaseSelectedPass() {
        guard !products.isEmpty else {
            print("No products available to purchase. Products array: \(products)")
            purchaseError = "No products available to purchase."
            return
        }
        
        guard currentUser != nil else {
            print("Current user is nil in purchaseSelectedPass. Auth state: \(Auth.auth().currentUser?.uid ?? "nil")")
            purchaseError = "Please sign in to purchase a pass."
            return
        }
        
        isPurchasing = true
        purchaseError = nil
        
        let product = products[selectedPassType]
        storeKitManager.purchaseProduct(product) { success, error in
            if success {
                self.updateSubscription(productId: product.productIdentifier)
            } else {
                self.purchaseError = "Purchase failed: \(error ?? "Unknown error")"
            }
            self.isPurchasing = false
        }
    }

    // Fetch user's subscription status from Firestore
    private func fetchUserSubscription() {
        guard let user = currentUser else {
            print("No user available to fetch subscription.")
            return
        }
        
        db.collection("subscriptions").document(user.uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching subscription: \(error.localizedDescription)")
                return
            }
            if let data = snapshot?.data(),
               let productId = data["productId"] as? String,
               let expirationTimestamp = data["expirationDate"] as? Timestamp {
                let expirationDate = expirationTimestamp.dateValue()
                let isActive = expirationDate > Date()
                self.userSubscription = SubscriptionStatus(productId: productId, expirationDate: expirationDate, isActive: isActive)
                print("Fetched subscription: \(productId), active: \(isActive)")
            } else {
                print("No subscription data found for user: \(user.uid)")
                self.userSubscription = nil
            }
        }
    }

    // Update Firestore with subscription details after purchase
    private func updateSubscription(productId: String) {
        guard let user = currentUser else {
            print("No user available to update subscription.")
            return
        }
        
        let calendar = Calendar.current
        let currentDate = Date()
        var expirationDate: Date
        
        switch productId {
        case productIdentifiers[0]: // Monthly
            expirationDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
        case productIdentifiers[1]: // Annual
            expirationDate = calendar.date(byAdding: .year, value: 1, to: currentDate)!
        default:
            return
        }

        let subscriptionData: [String: Any] = [
            "productId": productId,
            "purchaseDate": Timestamp(date: currentDate),
            "expirationDate": Timestamp(date: expirationDate),
            "userId": user.uid
        ]

        db.collection("subscriptions").document(user.uid).setData(subscriptionData) { error in
            if let error = error {
                print("Error saving subscription: \(error.localizedDescription)")
                self.purchaseError = "Failed to save subscription."
            } else {
                self.userSubscription = SubscriptionStatus(productId: productId, expirationDate: expirationDate, isActive: true)
                print("Subscription saved successfully for user: \(user.uid)")
            }
        }
    }
}

// MARK: - Subscription Status Model
struct SubscriptionStatus {
    let productId: String
    let expirationDate: Date
    let isActive: Bool
}

// MARK: - Supporting Views
struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(text)
        }
    }
}

struct ScootalPassView_Previews: PreviewProvider {
    static var previews: some View {
        ScootalPassView()
    }
}
