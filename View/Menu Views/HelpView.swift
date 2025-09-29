//
//  HelpView.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-02-25.
//

import SwiftUI

struct HelpView: View {
    @State private var expandedTopic: Int? = nil
    @State private var animateScooter = false
    @State private var scooterOffset: CGFloat = 0
    
    // Help topics with supportive, professional messaging
    let helpTopics = [
        ("Finding a Scooter", "Struggling to locate a ride? Use the map’s zoom feature or filter by availability. Need more options? We’ll suggest nearby hotspots!", "magnifyingglass", Color.blue),
        ("Meeting the Owner", "Arranging a meetup is easy—use in-app chat. If they’re delayed, our team can step in to mediate or find you another scooter fast.", "person.2", Color.green),
        ("Unlocking Help", "Key or code issues? Verify it with the owner or request a new one via ‘Support.’ We’ll get you rolling in no time!", "lock.open", Color.orange),
        ("Riding Tips", "First ride? Start slow: push off, throttle gently, and practice braking. Watch our 30-second tutorial for pro moves!", "scooter", Color.purple),
        ("Returning Smoothly", "Lock it, meet the owner, and confirm in-app. Lost contact? Use ‘Return Assist’—we’ll guide you to the finish line!", "arrowshape.turn.up.left", Color.teal),
        ("Billing Clarity", "Questions about charges? View your detailed ride history or dispute a fee. We’re here for full transparency!", "dollarsign", Color.yellow),
        ("Report an Issue", "Something off? Report damage or glitches in seconds—we’ll fix it and credit you for helping us improve Scootal!", "exclamationmark.triangle", Color.red),
        ("Talk to Us", "Need personalized help? Call, chat, or email our 24/7 support team. Your Scootal crew is always on standby!", "phone", Color.indigo)
    ]
    
    var body: some View {
        ZStack {
            // White background with subtle texture
            Color.white
                .overlay(
                    Image(systemName: "circle.grid.hex.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.gray.opacity(0.05))
                        .offset(x: -150, y: -300)
                )
                .edgesIgnoringSafeArea(.all)
            
            // Main content
            VStack(spacing: 0) {
                // Header with supportive tone
                HStack(spacing: 15) {
                    
                    VStack(alignment: .leading, spacing: 5) {
                        
                        Text("We’ve got you covered—let’s solve it!")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 30)
                .padding(.horizontal, 20)
                
                // Scrollable accordion-style topics
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(0..<helpTopics.count, id: \.self) { index in
                            HelpTopicCard(
                                title: helpTopics[index].0,
                                description: helpTopics[index].1,
                                icon: helpTopics[index].2,
                                color: helpTopics[index].3,
                                isExpanded: expandedTopic == index
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    expandedTopic = (expandedTopic == index) ? nil : index
                                    scooterOffset = CGFloat(index * 80) // Scooter follows selection
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            animateScooter = true
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Scootal Support Station")
    }
}

// Help Topic Card (Accordion Style)
struct HelpTopicCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(color.opacity(0.1)))
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.gray)
            }
            .padding(15)
            
            // Expanded content
            if isExpanded {
                Text(description)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.gray.opacity(0.9))
                    .padding(.horizontal, 15)
                    .padding(.bottom, 15)
                    .transition(.opacity)
                
                Button(action: {
                    print("Action tapped for \(title)!")
                }) {
                    Text("Take Action")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .frame(width: 140)
                        .background(color)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 15)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .gray.opacity(isExpanded ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
        .frame(maxWidth: .infinity)
    }
}

// Preview
struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}
