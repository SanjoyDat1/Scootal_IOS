//
//  SafetyView.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-02-25.
//

import SwiftUI

struct SafetyView: View {
    @State private var selectedTip: Int? = nil
    @State private var animateScooter = false
    @State private var showOverlay = false
    
    // Safety tips with catchy titles and detailed advice
    let safetyTips = [
        ("Helmet On, Worries Off", "Always wear a helmet—it’s your best defense against bumps. Scootal partners with campus stores for discounts!", "helmet.fill", Color.blue),
        ("Stay in Your Lane", "Stick to bike lanes or designated paths. No weaving through crowds—keep it smooth and safe.", "road.lanes", Color.green),
        ("Bell It, Don’t Yell It", "Use the bell to alert pedestrians. A quick ding beats a loud shout every time!", "bell.fill", Color.orange),
        ("Brake Like a Pro", "Ease into stops—gentle pressure on the brakes keeps you in control.", "hand.raised.fill", Color.purple),
        ("Lock It Tight", "Secure the scooter with the key or code every time you park. Protect your ride and the next rider’s!", "lock.shield.fill", Color.red),
        ("Eyes Up, Phone Down", "Keep your phone in your pocket while riding. Stay alert to dodge obstacles and enjoy the ride", "eye.fill", Color.teal),
        ("Park Smart", "Park scooters upright, off walkways. A tidy campus keepys everyone happy and owners love it!", "parkingsign.circle.fill", Color.yellow),
        ("Night Ride, Light Up", "Use lights or reflectors after dark. Be seen, stay safe - Scootal's got your back with gear tips!", "lightbulb.fill", Color.indigo)
    ]
    
    var body: some View {
        ZStack {
            // White background with subtle gradient
            LinearGradient(
                gradient: Gradient(colors: [.white, Color.gray.opacity(0.05)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {

                // Safety tips grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach(0..<safetyTips.count, id: \.self) { index in
                            SafetyTipCard(
                                title: safetyTips[index].0,
                                icon: safetyTips[index].2,
                                color: safetyTips[index].3,
                                isSelected: selectedTip == index
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedTip = (selectedTip == index) ? nil : index
                                    showOverlay = selectedTip != nil
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            
            // Overlay for expanded tip
            if showOverlay, let tipIndex = selectedTip {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation(.easeOut) {
                            selectedTip = nil
                            showOverlay = false
                        }
                    }
                
                SafetyTipDetail(
                    title: safetyTips[tipIndex].0,
                    description: safetyTips[tipIndex].1,
                    icon: safetyTips[tipIndex].2,
                    color: safetyTips[tipIndex].3
                )
            }
        }
        .onAppear {
            animateScooter = true
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Scootal Safety Hub")
    }
}

// Safety Tip Card
struct SafetyTipCard: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
                .padding(12)
                .background(Circle().fill(color.opacity(0.1)))
                .scaleEffect(animate ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .gray.opacity(isSelected ? 0.4 : 0.2), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .onAppear {
            animate = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

// Expanded Safety Tip Detail
struct SafetyTipDetail: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(color)
                .padding(20)
                .background(Circle().fill(color.opacity(0.2)))
                .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.black)
            
            Text(description)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .lineSpacing(5)
            
            Button(action: {
                // Placeholder for additional action (e.g., link to helmet discounts)
                print("Learn more tapped!")
            }) {
                Text("Learn More")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .frame(width: 160)
                    .background(color)
                    .clipShape(Capsule())
            }
            .padding(.top, 10)
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.3), radius: 15, x: 0, y: 10)
        )
        .frame(maxWidth: 350)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

// Creative Scooter Orbit Animation
struct ScooterOrbit: View {
    @State private var animateOrbit = false
    
    var body: some View {
        ZStack {
            // Orbit path
            Circle()
                .trim(from: 0.1, to: 0.9)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 3, dash: [8])
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(animateOrbit ? 360 : 0))
                .animation(
                    Animation.linear(duration: 6).repeatForever(autoreverses: false),
                    value: animateOrbit
                )
            
            // Scooter
            Image(systemName: "scooter")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .offset(x: animateOrbit ? 50 : -50)
                .rotationEffect(.degrees(animateOrbit ? 10 : -10))
                .shadow(color: .blue.opacity(0.2), radius: 3, x: 0, y: 1)
                .animation(
                    Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                    value: animateOrbit
                )
        }
        .onAppear {
            animateOrbit = true
        }
    }
}

// Preview
struct SafetyView_Previews: PreviewProvider {
    static var previews: some View {
        SafetyView()
    }
}
