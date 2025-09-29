//
//  SellerInfoView.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2024-12-24.
//

import SwiftUI

struct SellerInfoView: View {
    let userId: String
    @State private var user: User? = nil
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(UIColor(hex: "primary"))
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Profile Section
                VStack(spacing: 20) {
                    Circle()
                        .fill(Color(UIColor(hex: "primary")).opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(
                            AsyncImage(url: URL(string: "https://via.placeholder.com/120")) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .foregroundColor(Color(UIColor(hex: "primary")))
                                }
                            }
                        )
                        .shadow(radius: 10)
                    
                    Text("Sanjoy Datta")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(UIColor(hex: "primary")))
                    
                    VStack(spacing: 5) {
                        Text("949-795-7786")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("sanjoyd1@uci.edu")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Divider()
                    .background(Color(UIColor(hex: "primary")))
                    .padding(.horizontal)
                
                // About the Seller Section
                VStack(alignment: .center, spacing: 15) {
                    Text("About the Seller")
                        .font(.headline)
                        .foregroundColor(Color(UIColor(hex: "primary")))
                    
                    Text("Hi, I’m Sanjoy! I’m a UC Irvine student renting out my electric scooter. Feel free to contact me for more details!")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Back Button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.backward")
                        Text("Back")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor(hex: "primary")))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                .padding()
            }
            .padding(.vertical, 30)
        }
        .navigationTitle("User Information")
    }
}

struct UserInfoView_Previews: PreviewProvider {
    static var previews: some View {
        SellerInfoView(userId: "8yRpWfqr41QVHiQSojSIyGddn6N2")
    }
}
