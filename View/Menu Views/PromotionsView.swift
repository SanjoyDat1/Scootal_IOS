//
//  PromotionsView.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-02-24.
//

import SwiftUI

struct PromotionsView: View {
    @State private var selectedPromotion: Promotion?
    @State private var showingPromoDetails = false
    @State private var animateGradient = false
    
    let promotions: [Promotion] = [
        Promotion(title: "Scoot & Save", description: "Ride 5 times, get 50% off your next ride", icon: "bicycle"),
        Promotion(title: "Early Bird Special", description: "25% off rides before 9 AM", icon: "sunrise"),
        Promotion(title: "Weekend Warrior", description: "Unlimited rides for $15 all weekend", icon: "calendar"),
        Promotion(title: "Refer a Friend", description: "Both get $10 ride credit", icon: "person.2.fill"),
        Promotion(title: "Campus Commuter", description: "20% off rides to and from campus", icon: "building.columns")
    ]
    
    var body: some View {
        ZStack {
            
            ScrollView {
                VStack(spacing: 25) {
                    
                    // Promotion cards
                    ForEach(promotions) { promotion in
                        PromotionCard(promotion: promotion)
                            .onTapGesture {
                                self.selectedPromotion = promotion
                                self.showingPromoDetails = true
                            }
                    }
                    
                    // Daily Challenge
                    DailyChallengeView()
                }
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showingPromoDetails) {
            if let promo = selectedPromotion {
                PromoDetailView(promotion: promo)
            }
        }
    }
}

struct Promotion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
}

struct PromotionCard: View {
    let promotion: Promotion
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: promotion.icon)
                .font(.system(size: 30))
                .foregroundColor(Color(UIColor(hex: "accent")))
                .frame(width: 60, height: 60)
                .background(Color.white)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 5) {
                Text(promotion.title)
                    .font(.headline)
                    .foregroundColor(Color(UIColor(hex: "primary")))
                Text(promotion.description)
                    .font(.subheadline)
                    .foregroundColor(Color(UIColor(hex: "primary")).opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.white)
        }
        .padding()
        .background(Color(UIColor(hex: "primary")).opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct DailyChallengeView: View {
    var body: some View {
        VStack(spacing: 15) {
            Text("Daily Challenge")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(UIColor(hex: "primary")))
            
            Text("Take 3 rides today and earn a free ride!")
                .foregroundColor(Color(UIColor(hex: "primary")))
            
            ProgressView(value: 1, total: 3)
                .progressViewStyle(CustomProgressViewStyle())
                .frame(height: 10)
                .padding(.horizontal)
            
            Text("1 / 3 completed")
                .font(.caption)
                .foregroundColor(Color(UIColor(hex: "primary")))
        }
        .padding()
        .background(Color(UIColor(hex: "primary")).opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(UIColor(hex: "primary")).opacity(0.3))
                    .frame(height: 10)
                
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(UIColor(hex: "accent")))
                    .frame(width: CGFloat(configuration.fractionCompleted ?? 0) * geometry.size.width, height: 10)
            }
        }
    }
}

struct PromoDetailView: View {
    let promotion: Promotion
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(UIColor(hex: "primary")).ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: promotion.icon)
                    .font(.system(size: 60))
                    .foregroundColor(Color(UIColor(hex: "#FFFFFF")))
                    .frame(width: 120, height: 120)
                    .background(Color(UIColor(hex: "primary")))
                    .clipShape(Circle())
                
                Text(promotion.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(promotion.description)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                Button(action: {
                    // Apply promotion logic here
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Apply Promotion")
                        .font(.headline)
                        .foregroundColor(Color(UIColor(hex:"primary")))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.white)
                        .cornerRadius(15)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 50)
        }
    }
}

struct PromotionsView_Previews: PreviewProvider {
    static var previews: some View {
        PromotionsView()
    }
}
