//
//  ScooterAvailabilitySheetView.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-01-05.
//
import SwiftUI
import Firebase
import FirebaseFirestore

struct ScooterAvailabilitySheetView: View {
    var scooter: Scooter // The scooter being booked

    @Environment(\.presentationMode) var presentationMode
    @State private var availabilitySchedule = AvailabilitySchedule()
    @State private var showingConfirmation = false
    @State private var selectedTab = 0
    @Namespace private var animation

    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                header
                tabView
                ScrollView {
                    VStack(spacing: 20) {
                        if selectedTab == 0 {
                            quickSetupSection
                        } else {
                            weeklyScheduleSection
                        }
                        rentalOptionsSection
                    }
                    .padding()
                }
            }
        }
        .alert(isPresented: $showingConfirmation) {
            Alert(
                title: Text("Confirm Availability"),
                message: Text("Your scooter will be available for rent based on this schedule. You can always change it later."),
                primaryButton: .default(Text("Confirm")) {
                    saveAvailability()
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var header: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Set Availability")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: { showingConfirmation = true }) {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(width: 70, height: 36)
                            .background(Color.white)
                            .cornerRadius(18)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Add a subtle divider
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)
                    .padding(.top, 8)
            }
        }
        .frame(height: 90)
        .edgesIgnoringSafeArea(.top)
    }
    
    private var tabView: some View {
        HStack {
            TabButton(title: "Quick Setup", isSelected: selectedTab == 0, namespace: animation) {
                withAnimation(.spring()) { selectedTab = 0 }
            }
            TabButton(title: "Custom Schedule", isSelected: selectedTab == 1, namespace: animation) {
                withAnimation(.spring()) { selectedTab = 1 }
            }
        }
        .padding(.top)
    }
    
    private var quickSetupSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quick Setup")
                .font(.headline)
            
            QuickSetupButton(icon: "sun.max.fill", text: "I'm available all day, every day", color: .blue) {
                setAllDay()
            }
            
            QuickSetupButton(icon: "calendar", text: "I'm available on weekdays only", color: .green) {
                setWeekdaysOnly()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var weeklyScheduleSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weekly Schedule")
                .font(.headline)
            
            ForEach(DayOfWeek.allCases, id: \.self) { day in
                DayScheduleRow(
                    day: day,
                    availability: Binding(
                        get: { self.availabilitySchedule.dailyAvailability[day, default: DailyAvailability()] },
                        set: { self.availabilitySchedule.dailyAvailability[day] = $0 }
                    )
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var rentalOptionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Rental Options")
                .font(.headline)
            
            ToggleOption(title: "Allow 6-hour rentals", isOn: $availabilitySchedule.allow6HourRentals)
            ToggleOption(title: "Allow 24-hour rentals", isOn: $availabilitySchedule.allow24HourRentals)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func setAllDay() {
        for day in DayOfWeek.allCases {
            availabilitySchedule.dailyAvailability[day]?.isAvailable = true
            availabilitySchedule.dailyAvailability[day]?.startTime = Calendar.current.date(from: DateComponents(hour: 0, minute: 0)) ?? Date()
            availabilitySchedule.dailyAvailability[day]?.endTime = Calendar.current.date(from: DateComponents(hour: 23, minute: 59)) ?? Date()
        }
    }
    
    private func setWeekdaysOnly() {
        for day in DayOfWeek.allCases {
            if day == .saturday || day == .sunday {
                availabilitySchedule.dailyAvailability[day]?.isAvailable = false
            } else {
                availabilitySchedule.dailyAvailability[day]?.isAvailable = true
                availabilitySchedule.dailyAvailability[day]?.startTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
                availabilitySchedule.dailyAvailability[day]?.endTime = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
            }
        }
    }
    
    private func saveAvailability() {
        let db = Firestore.firestore()
        let scooterRef = db.collection("Scooters").document(scooter.id)
        
        var availabilityData: [String: Any] = [:]
        
        for (day, availability) in availabilitySchedule.dailyAvailability {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            
            let startTime = dateFormatter.string(from: availability.startTime)
            let endTime = dateFormatter.string(from: availability.endTime)
            
            availabilityData[day.rawValue.lowercased()] = [
                "isAvailable": availability.isAvailable,
                "startTime": startTime,
                "endTime": endTime
            ]
        }
        
        scooterRef.updateData(["allow6HourRentals": availabilitySchedule.allow6HourRentals]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document successfully updated")
            }
        }
        
        scooterRef.updateData(["allow24HourRentals": availabilitySchedule.allow24HourRentals]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document successfully updated")
            }
        }
        
        
        scooterRef.updateData(["availability": availabilityData]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            } else {
                print("Document successfully updated")
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(title)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                if isSelected {
                    Color.blue
                        .frame(height: 2)
                        .matchedGeometryEffect(id: "Tab", in: namespace)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickSetupButton: View {
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(text)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(10)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ToggleOption: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(.subheadline)
        }
        .toggleStyle(SwitchToggleStyle(tint: .blue))
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut, value: configuration.isPressed)
    }
}

struct DayScheduleRow: View {
    let day: DayOfWeek
    @Binding var availability: DailyAvailability
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(day.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Toggle("", isOn: $availability.isAvailable)
            }
            
            if availability.isAvailable {
                HStack {
                    DatePicker("", selection: $availability.startTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                    Text("to")
                    DatePicker("", selection: $availability.endTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
        }
        .padding(.vertical, 5)
    }
}

enum DayOfWeek: String, CaseIterable {
    case monday = "Monday", tuesday = "Tuesday", wednesday = "Wednesday", thursday = "Thursday", friday = "Friday", saturday = "Saturday", sunday = "Sunday"
}

struct AvailabilitySchedule {
    var dailyAvailability: [DayOfWeek: DailyAvailability] = Dictionary(uniqueKeysWithValues: DayOfWeek.allCases.map { ($0, DailyAvailability()) })
    var allow6HourRentals: Bool = true
    var allow24HourRentals: Bool = true
}

struct DailyAvailability {
    var isAvailable: Bool = true
    var startTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    var endTime: Date = Calendar.current.date(from: DateComponents(hour: 17, minute: 0)) ?? Date()
}

#Preview {
    UserProfileView()
}
