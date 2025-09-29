//
//  HowToRideView.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-02-24.
//
import SwiftUI

struct HowToRideView: View {
    @State private var currentStep = 0
    @State private var showScooterListView = false
    
    // Concise, actionable steps
    let steps = [
            ("Find Your Ride", "Students list their scooters on Scootal—find one nearby in seconds.", "magnifyingglass", Color.blue),
            ("Meet the Owner", "Chat with the owner in-app to set a meetup spot on campus. They’ll give you the lock code or key.", "person.2", Color.green),
            ("Ride Away", "Use the code or key to unlock. Push off, press the throttle, and cruise!", "scooter", Color.orange),
            ("Safety First", "URing the bell for pedestrians, stay in your lane, and brake gently to stop.", "plus.circle", Color.red),
            ("Lock & Return", "Meet the owner again, hand back the scooter, and mark it done in the app.", "lock", Color.purple)
        ]
    
    var body: some View {
        ZStack {
            // Clean white background
            Color.white
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Scooter header animation
                ScooterHeader()
                    .padding(.top, 20)
                
                // Steps in a swipeable view
                TabView(selection: $currentStep) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        StepCard(
                            title: steps[index].0,
                            description: steps[index].1,
                            icon: steps[index].2,
                            color: steps[index].3
                        )
                        .tag(index)
                    }
                }
                .padding(.bottom, 35)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Custom dots below
                .frame(height: 400)
                .overlay(
                    // Custom black dots
                    HStack(spacing: 10) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Circle()
                                .frame(width: 8, height: 8)
                                .foregroundColor(currentStep == index ? .black : .gray.opacity(0.4))
                                .animation(.easeInOut(duration: 0.3), value: currentStep)
                        }
                    }
                    .padding(.top, 420)
                )
                Spacer()
                
                // Navigation button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if currentStep < steps.count - 1 {
                            currentStep += 1
                        } else {
                            showScooterListView = true
                            print("User completed the guide!")
                        }
                    }
                }) {
                    Text(currentStep == steps.count - 1 ? "Get Started" : "Next")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: 300)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showScooterListView){
            ScooterListView()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("How Scootal Works Guide")
    }
}

// Step Card Component
struct StepCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon with subtle animation
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(color)
                .padding(16)
                .background(Circle().fill(color.opacity(0.1)))
                .overlay(Circle().stroke(color.opacity(0.9), lineWidth: 1))
                .scaleEffect(animate ? 1.0 : 0.9)
                .animation(.easeInOut(duration: 0.5), value: animate)
            
            // Title
            Text(title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            // Description
            Text(description)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.9), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
        .opacity(animate ? 1.0 : 0)
        .offset(y: animate ? 0 : 20)
        .animation(.spring(response: 0.1, dampingFraction: 0.9), value: animate)
        .onAppear {
            animate = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

// Scooter Header Animation
struct ScooterHeader: View {
    @State private var animate = false
    
    var body: some View {
        Image(systemName: "scooter")
            .font(.system(size: 90))
            .foregroundColor(.blue)
            .offset(x: animate ? 15 : -15)
            .rotationEffect(.degrees(animate ? 5 : -5))
            .shadow(color: .blue.opacity(0.2), radius: 5, x: 0, y: 2)
            .animation(
                Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                value: animate
            )
            .onAppear {
                animate = true
            }
    }
}

// Preview
struct HowItWorksView_Previews: PreviewProvider {
    static var previews: some View {
        HowToRideView()
    }
}
