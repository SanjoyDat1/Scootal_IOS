//
//  Untitled.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-02-24.
//
import SwiftUI

enum MenuPage: String {
    case home = "Home"
    case scootalPass = "Scootal Pass"
    case promotions = "Promotions"
    case payment = "Payment"
    case freeRides = "Free Rides"
    case howToRide = "How To Ride"
    case safety = "Safety"
    case help = "Scootal Support"
}

struct SlideOutMenu: View {
    @State private var isVisible = true
    @State private var selectedPage: MenuPage = .home
    @State private var showPageContent = false
    
    let menuItems: [(MenuPage, String)] = [
        (.scootalPass, "creditcard"),
        (.promotions, "gift"),
        (.payment, "dollarsign.circle"),
        (.freeRides, "bicycle"),
        (.howToRide, "book"),
        (.safety, "shield.checkerboard"),
        (.help, "questionmark.circle"),
    ]
    
    var body: some View {
        ZStack {
            // Blurred background
            BlurView(style: .systemThinMaterialDark)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack{
                    HStack {
                        Spacer()
                       
                    }
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    HStack {
                        Spacer()
                       
                    }
                    .padding()
                    .background(Color.blue.opacity(0.8))

                }
                
                
                // Menu items
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(menuItems, id: \.0) { item in
                            MenuItemView(title: item.0.rawValue, icon: item.1, isSelected: selectedPage == item.0)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        selectedPage = item.0
                                        showPageContent = true
                                        isVisible = false
                                    }
                                }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
        }
        .frame(width: UIScreen.main.bounds.width * 0.75)
        .edgesIgnoringSafeArea(.all)
        .fullScreenCover(isPresented: $showPageContent) {
            NavigationView {
                Group {
                    switch selectedPage {
                    case .scootalPass:
                        ScootalPassView()
                    case .promotions:
                        PromotionsView()
                    case .payment:
                        PaymentView()
                    case .freeRides:
                        Text("No Free Rides Available At This Time.")
                    case .howToRide:
                        HowToRideView()
                    case .safety:
                        SafetyView()
                    case .help:
                        HelpView()
                    case .home:
                        Text("Home Page")
                    }
                }
                .navigationTitle(selectedPage.rawValue)
                .navigationBarItems(leading: Button(action: {
                    showPageContent = false
                    isVisible = true
                }) {
                    Image(systemName: "xmark")
                })
            }
        }
    }
}

struct MenuItemView: View {
    let title: String
    let icon: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isSelected ? .white : .white)
                .frame(width: 30)
            Text(title)
                .foregroundColor(isSelected ? .white : .white)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.8) : Color.clear)
        .cornerRadius(10)
    }
}

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// Preview
struct SlideOutMenu_Previews: PreviewProvider {
    static var previews: some View {
        SlideOutMenu()
    }
}
