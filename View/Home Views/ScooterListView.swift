import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct ScooterListView: View {
    @State private var scooters: [Scooter] = []
    
    @State private var searchText = ""
    @State private var showingAddScooterView = false
    @State private var showUserProfileView = false
    @State private var showingMessagesView = false
    @State private var showCurrentBookingView = false
    @State private var isMenuVisible = false
    
    // Time picker state
    @State private var selectedPickupTime: Date = Date()
    @State private var showTimePicker = false
    @State private var selectedDuration: Int = 6
    private var selectedReturnTime: Date {
        selectedPickupTime.addingTimeInterval(TimeInterval(selectedDuration * 3600))
    }
    private let calendar = Calendar.current
    private let minAdvanceTime = 6 * 60 * 60 // 6 hours in seconds
    private let maxAdvanceTime = 7 * 7 * 24 * 60 * 60 // 7 weeks in seconds
    
    // Enhanced state for filtering, sorting, and location
    @State private var selectedLocation: String = "UC Irvine"
    @State private var sortOption: SortOption = .relevance
    @State private var availableLocations: [String] = ["Aldrich Park", "Anteatery", "Science Library", "Flagpoles"]
    @State private var showFilters = false
    
    enum SortOption: String, CaseIterable {
        case relevance = "Relevance"
        case priceLowToHigh = "Price: Low to High"
        case priceHighToLow = "Price: High to Low"
        case speed = "Top Speed"
    }
    
    private let primaryColor = Color(UIColor(hex: "primary"))
    private let accentColor = Color(UIColor(hex: "accent"))
    private let backgroundColor = Color(red: 0.95, green: 0.96, blue: 0.97)
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "scooter")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                            Text("Scootal")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { withAnimation { showUserProfileView.toggle() } }) {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        SearchBar(text: $searchText)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 10)
                    .background(primaryColor)
                    .shadow(color: .black.opacity(0.1), radius: 5)
                    
                    // Filter and Sort Bar with Time Picker Button
                    HStack(spacing: 12) {
                        Button(action: { showTimePicker.toggle() }) {
                            Image(systemName: "clock")
                                .font(.system(size: 14))
                                .foregroundColor(Color(UIColor(hex: "primary")))
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: .gray.opacity(0.2), radius: 3)
                        }
                        
                        Menu {
                            ForEach(availableLocations, id: \.self) { location in
                                Button(location) { selectedLocation = location }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 14))
                                Text(selectedLocation)
                                    .font(.system(size: 14, weight: .medium))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: .gray.opacity(0.2), radius: 3)
                        }
                        
                        Spacer()
                        
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(option.rawValue) { sortOption = option }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 14))
                                Text(sortOption.rawValue)
                                    .font(.system(size: 14, weight: .medium))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: .gray.opacity(0.2), radius: 3)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(backgroundColor)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Featured Scooters")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(primaryColor)
                                    Spacer()
                                    Text("Boosted Visibility")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(accentColor)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(filteredFeaturedScooters.prefix(5), id: \.id) { scooter in
                                            NavigationLink(destination: ScooterDetailView(scooter: scooter, startTime: selectedPickupTime, endTime: selectedReturnTime, selectedDuration: selectedDuration)) {
                                                FeaturedScooterCardView(scooter: scooter, selectedDuration: selectedDuration)
                                                    .frame(width: 215, height: 330)
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, 10)
                            
                            LazyVStack(spacing: 16) {
                                ForEach(filteredAndSortedScooters, id: \.id) { scooter in
                                    NavigationLink(destination: ScooterDetailView(scooter: scooter, startTime: selectedPickupTime, endTime: selectedReturnTime, selectedDuration: selectedDuration)) {
                                        ScooterCardView(scooter: scooter, selectedDuration: selectedDuration)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                        .padding(.bottom, 100)
                    }
                }
                
                // Bottom Navigation
                VStack {
                    Spacer()
                    HStack(spacing: 40) {
                        NavButton(icon: "ellipsis.circle", label: "More", action: { isMenuVisible = true })
                        NavButton(icon: "plus.circle.fill", label: "Add", action: { showingAddScooterView = true }, isHighlighted: true)
                        NavButton(icon: "message", label: "Messages", action: { showingMessagesView = true })
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.white)
                    .cornerRadius(30)
                    .shadow(color: .black.opacity(0.2), radius: 10)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                fetchScooters()
                fetchUserBookingStatus()
                checkAndUpdateAllScootersAvailability()
                updateAvailableLocations()
                selectedPickupTime = Date().addingTimeInterval(TimeInterval(minAdvanceTime))
            }
            .sheet(isPresented: $showingAddScooterView) { AddScooterView() }
            .sheet(isPresented: $showingMessagesView) { MessagesView() }
            .fullScreenCover(isPresented: $showCurrentBookingView) { CurrentBookingView(userId: Auth.auth().currentUser?.uid ?? "") }
            .overlay {
                ZStack(alignment: .leading) {
                    if isMenuVisible {
                        Color.black.opacity(0.5)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    isMenuVisible = false
                                }
                            }
                    }
                    
                    SlideOutMenu()
                        .frame(width: UIScreen.main.bounds.width * 0.75)
                        .offset(x: isMenuVisible ? 0 : -(UIScreen.main.bounds.width * 0.75 + 50))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isMenuVisible)
                        .zIndex(isMenuVisible ? 0 : 0)
                    
                    if showUserProfileView {
                        UserProfileView()
                            .transition(.move(edge: .trailing))
                            .animation(.easeInOut(duration: 0.3), value: showUserProfileView)
                            .zIndex(2)
                    }
                }
            }
            .sheet(isPresented: $showTimePicker) {
                VStack(spacing: 24) {
                    HStack {
                        Text("Schedule Your Ride")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(UIColor(hex: "primary")))
                        Spacer()
                        Button(action: { showTimePicker = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pick-up Time")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray)

                        DatePicker("", selection: $selectedPickupTime, in: dateRange(), displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.2), radius: 5)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ride Duration")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray)

                        HStack(spacing: 12) {
                            DurationButton(title: "6 Hours", selected: selectedDuration == 6) {
                                selectedDuration = 6
                            }
                            DurationButton(title: "24 Hours", selected: selectedDuration == 24) {
                                selectedDuration = 24
                            }
                        }
                    }
                    .padding(.horizontal)

                    Button(action: { showTimePicker = false }) {
                        Text("Find \(selectedDuration)-Hour Rides")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor(hex: "primary")))
                            .cornerRadius(25)
                            .shadow(color: Color(UIColor(hex: "primary")).opacity(0.3), radius: 5)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity, maxHeight: 540, alignment: .center)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .padding(.horizontal, 16)
                .presentationDetents([.height(555)])
            }
        }
    }
    
    private func fetchScooters() {
        let db = Firestore.firestore()
        db.collection("Scooters").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching scooters: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No scooters found")
                return
            }
            
            self.scooters = documents.map { document in
                let data = document.data()
                var availabilityDict: [String: Scooter.DailyAvailability] = [:]
                if let availabilityData = data["availability"] as? [String: [String: Any]] {
                    for (day, dayData) in availabilityData {
                        let dailyAvailability = Scooter.DailyAvailability(
                            isAvailable: dayData["isAvailable"] as? Bool ?? false,
                            startTime: dayData["startTime"] as? String ?? "00:00",
                            endTime: dayData["endTime"] as? String ?? "23:59"
                        )
                        availabilityDict[day] = dailyAvailability
                    }
                }
                
                return Scooter(
                    id: document.documentID,
                    description: data["description"] as? String ?? "",
                    imageURL: data["imageURL"] as? String ?? "",
                    isAvailable: data["isAvailable"] as? Bool ?? false,
                    isBooked: data["isBooked"] as? Bool ?? false,
                    activeBooking: data["activeBooking"] as? Bool ?? false,
                    isFeatured: data["isFeatured"] as? Bool ?? false,
                    confirmationCode: data["confirmationCode"] as? String ?? "",
                    location: data["location"] as? String ?? "",
                    totalPricePerHour: data["totalPricePerHour"] as? Double ?? 0.0,
                    allow6HourRentals: data["allow6HourRentals"] as? Bool ?? false,
                    allow24HourRentals: data["allow24HourRentals"] as? Bool ?? false,
                    eympaFeePerHour: data["eympaFeePerHour"] as? Double ?? 0.0,
                    userPricePerHour: data["userPricePerHour"] as? Double ?? 0.0,
                    sixHourPrice: data["sixHourPrice"] as? Double ?? 0.0,
                    fullDayPrice: data["fullDayPrice"] as? Double ?? 0.0,
                    isElectric: data["isElectric"] as? Bool ?? false,
                    range: data["range"] as? Int ?? 0,
                    brand: data["brand"] as? String ?? "",
                    modelName: data["modelName"] as? String ?? "",
                    yearOfMake: data["yearOfMake"] as? String ?? "",
                    damages: data["damages"] as? String ?? "",
                    restrictions: data["restrictions"] as? String ?? "",
                    specialNotes: data["specialNotes"] as? String ?? "",
                    scooterName: data["scooterName"] as? String ?? "",
                    topSpeed: data["topSpeed"] as? Int ?? 0,
                    ownerID: data["ownerID"] as? String ?? "",
                    isConfirmed: data["isConfirmed"] as? Bool ?? false,
                    unavailableAt: data["unavailableAt"] as? Timestamp ?? Timestamp(date: Date()),
                    availability: availabilityDict
                )
            }
        }
    }
    
    private func dateRange() -> ClosedRange<Date> {
        let now = Date()
        let minDate = now.addingTimeInterval(TimeInterval(minAdvanceTime))
        let maxDate = now.addingTimeInterval(TimeInterval(maxAdvanceTime))
        return minDate...maxDate
    }
    
    var filteredAndSortedScooters: [Scooter] {
        var scooters = self.scooters.filter { scooter in
            let isAvailable = isScooterAvailableAtTime(scooter: scooter, time: selectedPickupTime)
            let supportsDuration = (selectedDuration == 24 && scooter.allow24HourRentals) ||
                                   (selectedDuration == 6 && scooter.allow6HourRentals)
            return isAvailable && supportsDuration
        }

        if selectedLocation != "UC Irvine" {
            scooters = scooters.filter { $0.location == selectedLocation }
        }

        if !searchText.isEmpty {
            scooters = scooters.filter {
                $0.scooterName.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOption {
        case .relevance:
            return scooters.sorted { $0.isFeatured && !$1.isFeatured }
        case .priceLowToHigh:
            return scooters.sorted {
                let price1 = selectedDuration == 6 ? $0.sixHourPrice : $0.fullDayPrice
                let price2 = selectedDuration == 6 ? $1.sixHourPrice : $1.fullDayPrice
                return price1 < price2
            }
        case .priceHighToLow:
            return scooters.sorted {
                let price1 = selectedDuration == 6 ? $0.sixHourPrice : $0.fullDayPrice
                let price2 = selectedDuration == 6 ? $1.sixHourPrice : $1.fullDayPrice
                return price1 > price2
            }
        case .speed:
            return scooters.sorted { $0.topSpeed > $1.topSpeed }
        }
    }
    
    var filteredFeaturedScooters: [Scooter] {
        var scooters = self.scooters.filter { scooter in
            let isAvailable = scooter.isFeatured && isScooterAvailableAtTime(scooter: scooter, time: selectedPickupTime)
            let supportsDuration = (selectedDuration == 24 && scooter.allow24HourRentals) ||
                                   (selectedDuration == 6 && scooter.allow6HourRentals)
            return isAvailable && supportsDuration
        }
        
        if selectedLocation != "UC Irvine" {
            scooters = scooters.filter { $0.location == selectedLocation }
        }
        
        return scooters.shuffled()
    }
    
    private func isScooterAvailableAtTime(scooter: Scooter, time: Date) -> Bool {
        let dayOfWeek = calendar.component(.weekday, from: time) - 1
        let daysOfWeek = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        let dayString = daysOfWeek[dayOfWeek]
        
        guard let dailyAvailability = scooter.availability[dayString] else {
            return false
        }
        
        guard dailyAvailability.isAvailable else {
            return false
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        guard let startTime = dateFormatter.date(from: dailyAvailability.startTime),
              let endTime = dateFormatter.date(from: dailyAvailability.endTime) else {
            return false
        }
        
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        let startOfDay = calendar.startOfDay(for: time)
        
        guard let pickupTimeDate = calendar.date(bySettingHour: timeComponents.hour!, minute: timeComponents.minute!, second: 0, of: startOfDay),
              let startTimeDate = calendar.date(bySettingHour: calendar.component(.hour, from: startTime), minute: calendar.component(.minute, from: startTime), second: 0, of: startOfDay),
              let endTimeDate = calendar.date(bySettingHour: calendar.component(.hour, from: endTime), minute: calendar.component(.minute, from: endTime), second: 59, of: startOfDay) else {
            return false
        }
        
        return pickupTimeDate >= startTimeDate && pickupTimeDate <= endTimeDate
    }
    
    private func updateAvailableLocations() {
        let locations = Set(scooters.map { $0.location })
        availableLocations = ["UC Irvine", "Aldrich Park", "Anteatery - Mesa Court", "Science Library", "Langson Library", "Anteater Recreation Center"] + locations.sorted()
    }
    
    func fetchUserBookingStatus() {
        guard let user = Auth.auth().currentUser else {
            print("No user signed in.")
            return
        }
        
        let db = Firestore.firestore()
        let userId = user.uid
        
        db.collection("Users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user document: \(error)")
                return
            }
            
            guard let data = snapshot?.data(), let isBooked = data["isBooking"] as? Bool else {
                print("isBooked field not found or invalid.")
                return
            }
            
            DispatchQueue.main.async {
                self.showCurrentBookingView = isBooked
            }
        }
    }
    
    func checkAndUpdateAllScootersAvailability() {
        let db = Firestore.firestore()
        let scootersRef = db.collection("Scooters")
        
        scootersRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting scooters: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                print("No scooters found")
                return
            }
            
            let currentDate = Date()
            let currentDay = calendar.component(.weekday, from: currentDate) - 1
            let daysOfWeek = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
            let currentDayString = daysOfWeek[currentDay]
            
            for document in documents {
                let scooterID = document.documentID
                if let availabilityData = document.data()["availability"] as? [String: [String: Any]],
                   let dayAvailability = availabilityData[currentDayString] as? [String: Any],
                   let isAvailableForDay = dayAvailability["isAvailable"] as? Bool,
                   let startTimeString = dayAvailability["startTime"] as? String,
                   let endTimeString = dayAvailability["endTime"] as? String {
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "HH:mm"
                    
                    if let startTime = dateFormatter.date(from: startTimeString),
                       let endTime = dateFormatter.date(from: endTimeString) {
                        
                        let startOfDay = calendar.startOfDay(for: currentDate)
                        let currentTimeComponents = calendar.dateComponents([.hour, .minute], from: currentDate)
                        let startTimeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
                        let endTimeComponents = calendar.dateComponents([.hour, .minute], from: endTime)
                        
                        let currentTimeDate = calendar.date(bySettingHour: currentTimeComponents.hour!, minute: currentTimeComponents.minute!, second: 0, of: startOfDay)!
                        let startTimeDate = calendar.date(bySettingHour: startTimeComponents.hour!, minute: startTimeComponents.minute!, second: 0, of: startOfDay)!
                        let endTimeDate = calendar.date(bySettingHour: endTimeComponents.hour!, minute: endTimeComponents.minute!, second: 59, of: startOfDay)!
                        
                        let shouldBeAvailable = isAvailableForDay && (currentTimeDate >= startTimeDate && currentTimeDate <= endTimeDate)
                        
                        let tempDocRef = db.collection("Scooters").document(scooterID)
                        tempDocRef.updateData([
                            "isAvailable": shouldBeAvailable
                        ]) { error in
                            if let error = error {
                                print("Error updating document: \(error)")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct DurationButton: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(selected ? .white : .gray)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(selected ? Color(UIColor(hex: "primary")) : Color(.systemGray6))
                .cornerRadius(12)
                .shadow(color: selected ? Color(UIColor(hex: "primary")).opacity(0.3) : .clear, radius: 3)
        }
    }
}

struct FeaturedScooterCardView: View {
    let scooter: Scooter
    let selectedDuration: Int
    private let accentColor = Color(UIColor(hex: "accent"))
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: scooter.imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 180, height: 180)
                            .clipped()
                            .cornerRadius(12)
                    default:
                        ProgressView()
                            .frame(width: 180, height: 180)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                Text("Featured")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accentColor)
                    .cornerRadius(8)
                    .padding(8)
            }
            
            Text(scooter.scooterName)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
                .lineLimit(1)
            
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Text(scooter.location)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Text(selectedDuration == 6 ? "$\(String(format: "%.2f", scooter.sixHourPrice))/6hrs" : "$\(String(format: "%.2f", scooter.fullDayPrice))/day")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 0.0, green: 0.48, blue: 0.73))
            
            Text("Speed: \(scooter.topSpeed) mph")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

struct ScooterCardView: View {
    let scooter: Scooter
    let selectedDuration: Int
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: scooter.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(10)
                default:
                    ProgressView()
                        .frame(width: 100, height: 100)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(scooter.scooterName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                HStack {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(scooter.location)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Text(selectedDuration == 6 ? "$\(String(format: "%.2f", scooter.sixHourPrice))/6hr" : "$\(String(format: "%.2f", scooter.fullDayPrice))/day")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(UIColor(hex: "primary")))
                
                Text("Speed: \(scooter.topSpeed) mph")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search scooters...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .submitLabel(.search)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.2), radius: 3)
    }
}

struct NavButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    var isHighlighted: Bool = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isHighlighted ? Color(red: 0.0, green: 0.48, blue: 0.73) : .gray)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isHighlighted ? Color(red: 0.0, green: 0.48, blue: 0.73) : .gray)
            }
        }
        .frame(width: 65)
    }
}

struct FilterOverlay: View {
    @Binding var showFilters: Bool
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Text("Advanced Filters")
                    .font(.system(size: 20, weight: .bold))
                Button("Apply") { showFilters = false }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.0, green: 0.48, blue: 0.73))
                    .cornerRadius(10)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 10)
            .frame(maxWidth: .infinity)
        }
        .background(Color.black.opacity(0.5).onTapGesture { showFilters = false })
    }
}

struct ScooterListView_Previews: PreviewProvider {
    static var previews: some View {
        ScooterListView()
    }
}


struct ScooterDetailView: View {
    let scooter: Scooter
    let startTime: Date
    let endTime: Date
    let selectedDuration: Int
    
    @State private var showSellerInfo = false
    @State private var showBookingView = false
    @State private var returnToScooterListView = false
    @State private var ownerImageURL: URL? = nil
    @State private var showUserInfo = false
    @State private var ownerName: String = "******"
    @State private var ownerEmail: String = "******"
    @State private var ownerPhone: String = "n/a" // Example phone number from Firebase

    private let primaryColor = Color(UIColor(hex: "primary"))
    private let accentColor = Color.orange
    private let backgroundColor = Color(UIColor.systemBackground)

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Scootal")
                    .font(.system(size: 45, weight: .bold))
                    .foregroundColor(Color(UIColor(hex: "primary")))
                    .padding(.horizontal, 10)
                    .padding(.top, 5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                HeroImageSection(imageURL: scooter.imageURL)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .shadow(radius: 5)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 15) {
                    Text(scooter.scooterName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text("Brand: \(scooter.brand)")
                        Spacer()
                        Text("Model: \(scooter.modelName)")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    
                    HStack {
                        FeatureTag(icon: "bolt.fill", text: scooter.isElectric ? "Electric" : "Manual")
                        FeatureTag(icon: "road.lanes", text: "\(scooter.range) mi range")
                        FeatureTag(icon: "speedometer", text: "\(scooter.topSpeed) mph")
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pickup Location")
                            .font(.headline)
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                            Text(scooter.location)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(scooter.description)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    if !scooter.restrictions.isEmpty || !scooter.specialNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rules & Notes")
                                .font(.headline)
                            if !scooter.restrictions.isEmpty {
                                Text("Restrictions: \(scooter.restrictions)")
                                    .foregroundColor(.secondary)
                            }
                            if !scooter.specialNotes.isEmpty {
                                Text("Notes: \(scooter.specialNotes)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    if !scooter.damages.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Damages")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text(scooter.damages)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Section Header
                        Text("Owner Information")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.top)

                        // Profile Information Section
                        HStack {
                            // Profile Image
                            if let imageURL = ownerImageURL {
                                AsyncImage(url: imageURL) { image in
                                    image.resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 3)) // Border for profile image
                                        .shadow(radius: 5)
                                } placeholder: {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                }
                            } else {
                                Color.gray.opacity(0.3)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 3))
                            }

                            Spacer()

                            // Show/Hide Info Button
                            Button(action: { withAnimation { showUserInfo.toggle() } }) {
                                HStack {
                                    Image(systemName: showUserInfo ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 18))
                                    Text(showUserInfo ? "Hide Info" : "Show Info")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }

                        // Owner Info Display
                        VStack(alignment: .leading, spacing: 4) {
                            if showUserInfo {
                                Text("Name: \(ownerName)")
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Text("Email: \(ownerEmail)")
                                    .font(.body)
                                    .foregroundColor(.primary)

                                // Make the phone number clickable
                                Link(destination: URL(string: "sms:\(ownerPhone)")!) {
                                    Text("Phone: \(ownerPhone)")
                                        .font(.body)
                                        .foregroundColor(.blue)
                                }
                            } else {
                                Text("Name: ******")
                                    .font(.body)
                                    .foregroundColor(.gray)

                                Text("Email: ******")
                                    .font(.body)
                                    .foregroundColor(.gray)

                                Text("Phone: ******")
                                    .font(.body)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 8)
                        .transition(.opacity) // Smooth transition effect when showing/hiding info
                    }

                }
                .padding(.horizontal)
            }
            .padding(.bottom, 130)
        }
        .navigationBarTitleDisplayMode(.inline)
        .overlay(
            VStack {
                Spacer()
                HStack(spacing: 15) {
                    ContactSellerButton { showSellerInfo = true }
                    BookingButton(isAvailable: scooter.isAvailable) { showBookingView = true }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(radius: 5)
            }
            .padding(), alignment: .bottom
        )
        .sheet(isPresented: $showBookingView) {
            BookingView(scooter: scooter, startTime: startTime, endTime: endTime, selectedDuration: selectedDuration)
        }
        .fullScreenCover(isPresented: $showSellerInfo) {
            SellerInfoView(userId: scooter.ownerID)
        }
        .onAppear {
            fetchOwnerImage()
            fetchOwnerInfo()
        }
    }
    
    private func fetchOwnerImage() {
        let storageRef = Storage.storage().reference().child("users/\(scooter.ownerID)/face.jpg")
        storageRef.downloadURL { url, error in
            if let error = error {
                print("Error fetching face image URL: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self.ownerImageURL = url
            }
        }
    }
    
    private func fetchOwnerInfo() {
        let db = Firestore.firestore()
        db.collection("Users").document(scooter.ownerID).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                DispatchQueue.main.async {
                    self.ownerName = "\(data?["firstName"] as? String ?? "") \(data?["lastName"] as? String ?? "")"
                    self.ownerEmail = data?["schoolEmail"] as? String ?? "******"
                    self.ownerPhone = data?["phoneNumber"] as? String ?? "n/a"
                }
            } else {
                print("Error fetching owner info: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}




struct FeatureTag: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue)
        .clipShape(Capsule())
    }
}

struct ContactSellerButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Message")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.blue)
                .padding()
                .background(Color.blue.opacity(0.2))
                .clipShape(Capsule())
        }
    }
}

struct BookingButton: View {
    let isAvailable: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Book This Ride")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .clipShape(Capsule())
        }
    }
}
struct HeroImageSection: View {
    let imageURL: String
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                case .empty, .failure:
                    Color.gray.opacity(0.2)
                        .overlay(
                            Image(systemName: "scooter")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                        )
                @unknown default:
                    EmptyView()
                }
            }}}}
