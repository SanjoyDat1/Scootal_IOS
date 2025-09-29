# Scootal - Peer-to-Peer Scooter Rental Platform

Scootal is a comprehensive iOS application built with SwiftUI that enables students to rent electric scooters from other students on campus. The app provides a complete marketplace experience with integrated payment processing, user authentication, and real-time availability tracking.

## 🚀 Features

### For Renters
- **Browse Available Scooters**: Search and filter scooters by location, price, and availability
- **Advanced Booking**: Schedule rides up to 7 weeks in advance with flexible 6-hour or 24-hour rental options
- **Secure Payments**: Stripe Connect integration with Apple Pay support
- **Real-time Availability**: View scooter availability based on owner-set schedules
- **Booking Management**: View current and past bookings with detailed receipts
- **Safety Features**: Built-in safety guidelines and helmet recommendations
- **Scootal Pass**: Monthly ($2.99) or Annual ($29.99) subscriptions with no unlock fees

### For Scooter Owners
- **List Your Scooter**: Multi-step listing process with detailed information and photo uploads
- **Flexible Pricing**: Set custom hourly and daily rates with late fee options
- **Protection Plans**: Optional damage/theft protection with four tiers (Opt-Out, Basic, Standard, Premium)
- **Availability Control**: Set custom availability schedules by day and time
- **Earnings Dashboard**: Track rental history and net earnings after fees
- **Featured Listings**: Boost visibility for $1 via Apple Pay
- **Stripe Connect**: Direct payouts to your bank account

## 🏗️ Technical Architecture

### Tech Stack
- **Frontend**: SwiftUI (iOS)
- **Backend**: Firebase (Authentication, Firestore, Storage, Cloud Functions, Messaging)
- **Payments**: Stripe Connect + Apple Pay
- **Subscriptions**: StoreKit (In-App Purchases)
- **Image Processing**: TOCropViewController for image cropping
- **Phone Input**: iPhoneNumberField for international phone numbers

### Data Models
- `User`: User profiles with authentication and booking history
- `Scooter`: Scooter details including pricing, availability, and owner information
- `Booking`: Rental bookings with status tracking and payment details
- `Message`: In-app messaging system (Coming Soon)
- `Renter`: Renter information for owner rental history
- `DamageEntry`: Damage reporting with photos and descriptions
- `SubscriptionStatus`: Scootal Pass subscription management

### Firebase Integration
- **Authentication**: Email/password with email verification
- **Firestore Collections**:
  - `Users`: User profiles and settings
  - `Scooters`: Scooter listings and availability
  - `Bookings`: Active and historical bookings
  - `providers`: Stripe Connect account information
  - `subscriptions`: Scootal Pass subscriptions
  - `payment_intents`: Payment tracking
  - `schoolRequests`: School expansion requests
  - `ReportedIssues`: Customer support tickets

- **Storage**: User photos (ID, face), scooter images, damage reports
- **Cloud Functions**:
  - `createConnectedAccount`: Onboard scooter owners to Stripe
  - `createPaymentIntent`: Process rental payments with platform fees
  - `stripeWebhook`: Handle Stripe account and payment events
  - `handleSuccessfulPayment`: Confirm bookings after payment

- **Messaging**: FCM token management for push notifications

## 📱 App Flow

### Authentication Flow
1. User signs up with email (UC Irvine `.edu` email required)
2. Multi-step registration:
   - Personal information
   - Survey questions (transportation habits)
   - Identity verification (ID and face photo upload with cropping)
   - Account setup (email and password)
3. Email verification required before login
4. Login with email/password
5. Forgot password flow available

### Renting Flow
1. Browse available scooters in `ScooterListView`
2. Filter by location, sort by price/speed
3. Select pickup time (minimum 6 hours advance) and duration (6 or 24 hours)
4. View scooter details including features, damages, and owner info
5. Book scooter with payment via Stripe/Apple Pay
6. Receive confirmation code
7. Meet owner for scooter pickup
8. Active booking displayed in `CurrentBookingView`
9. Return scooter with confirmation code verification
10. View receipt and past bookings

### Listing Flow
1. Navigate to "Add Scooter" from profile
2. Multi-step listing process:
   - Basic information (name, brand, model, year)
   - Photo upload with cropping
   - Scooter details (description, serial number, value, range)
   - Protection plan selection
   - Pricing (6-hour, 24-hour, late fees)
   - Performance (top speed) and pickup location
   - Additional info (damages, restrictions, special notes)
3. Set availability schedule (quick setup or custom by day/time)
4. Scooter listed and visible to renters
5. Receive booking requests with accept/deny options
6. Track earnings in owner dashboard

### Payment Flow
1. Renter selects scooter and rental duration
2. App calculates total price (base + unlock fee + taxes)
3. Firebase Function creates Payment Intent via Stripe Connect
4. Payment processed with 15% platform fee
5. 85% transferred to scooter owner's connected account
6. Booking confirmed and saved to Firestore
7. Push notification sent to owner
8. Renter can view receipt and report issues

## 🔐 Security & Privacy

- Firebase Authentication with email verification
- ID and face photo verification during signup
- Secure image storage with Firebase Storage
- PCI-compliant payment processing via Stripe
- Owner contact information hidden until booking confirmation
- FCM tokens securely stored for push notifications

## 💰 Pricing & Fees

### For Renters
- **Per-Ride Pricing**: Set by scooter owners
  - Minimum 6-hour rate: 1% of scooter value or protection plan minimum
  - Minimum 24-hour rate: 2% of scooter value or protection plan minimum
- **Platform Fees**: 15% + $1 unlock fee (included in displayed price)
- **Late Fees**: Set by owners (per 15-minute increment)
- **Scootal Pass**:
  - Monthly: $2.99 (no unlock fees)
  - Annual: $29.99 (no unlock fees)

### For Owners
- **Platform Fee**: 20% of rental price
- **Unlock Fee**: $1 per rental (kept by platform)
- **Protection Plan** (Optional):
  - Basic: $1 (6hr) / $2 (24hr) - covers $30 damage, $60 loss/theft
  - Standard: $2 (6hr) / $4 (24hr) - covers $50 damage, $110 loss/theft
  - Premium: $5 (6hr) / $10 (24hr) - covers $80 damage, $200 loss/theft
- **Featured Listing**: $1 one-time fee via Apple Pay

## 📦 Installation & Setup

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- CocoaPods or Swift Package Manager
- Firebase project
- Stripe account with Connect enabled
- Apple Developer account (for StoreKit and Apple Pay)

### Dependencies
```swift
// Firebase
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseMessaging
import FirebaseFunctions

// Stripe
import StripePaymentSheet
import StripeConnect

// UI
import TOCropViewController
import iPhoneNumberField

// Apple
import PassKit
import StoreKit
```

### Firebase Setup
1. Create Firebase project at console.firebase.google.com
2. Add iOS app with bundle identifier
3. Download `GoogleService-Info.plist` to Xcode project
4. Enable Authentication (Email/Password)
5. Create Firestore database
6. Set up Storage with security rules
7. Configure Cloud Messaging for push notifications
8. Deploy Cloud Functions:
   ```bash
   cd firebase_functions
   firebase deploy --only functions
   ```

### Stripe Setup
1. Create Stripe account at stripe.com
2. Enable Stripe Connect (Express accounts)
3. Get publishable key: `pk_live_...`
4. Configure Firebase Functions with secret key:
   ```bash
   firebase functions:config:set stripe.secret_key="sk_live_..."
   firebase functions:config:set stripe.webhook_secret="whsec_..."
   ```
5. Set up webhooks:
   - `account.updated` → `stripeWebhook` function
   - `payment_intent.succeeded` → `handleSuccessfulPayment` function

### StoreKit Setup
1. Create In-App Purchase products in App Store Connect:
   - Monthly subscription: `com.eympa.Eympa.scootalpass.monthly`
   - Annual subscription: `com.eympa.Eympa.scootalpass.annual`
2. Configure local StoreKit configuration file
3. Test subscriptions in sandbox environment

### Apple Pay Setup
1. Add merchant identifier: `merchant.com.Scootal.scootal`
2. Configure merchant ID in Apple Developer portal
3. Enable Apple Pay capability in Xcode
4. Add entitlements:
   ```xml
   <key>com.apple.developer.in-app-payments</key>
   <array>
       <string>merchant.com.Scootal.scootal</string>
   </array>
   ```

## 🔧 Configuration

### Info.plist
```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos of your scooter and ID</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photos to select scooter images</string>
```

### Firebase Security Rules
See `firebase_functions/firestore.rules` and `firebase_functions/storage.rules`

### Stripe Configuration
Update in `BookingView.swift`:
```swift
StripeAPI.defaultPublishableKey = "pk_live_51QeTUuIWrE69S61q7W01X8ZQBk5fE92SFd5ociPzhp1ifM7ddoSJGrQJ9dVH0mXcmMH1L8vyNtJmx38kou01WuIs00hdlsuXF7"
```

## 📂 Project Structure

```
Scootal/
├── EypmaApp.swift                    # App entry point with Firebase initialization
├── ContentView.swift                 # Root view with auth routing
├── View/
│   ├── Login Views/
│   │   ├── ScootalSignUp.swift       # Multi-step signup with ID verification
│   │   ├── Login.swift               # Email/password login
│   │   ├── ForgotPassword.swift      # Password reset
│   │   └── SchoolRequestView.swift   # Request new school support
│   ├── Home Views/
│   │   ├── ScooterListView.swift     # Main scooter browsing
│   │   ├── BookingView.swift         # Payment and booking confirmation
│   │   ├── CurrentBookingView.swift  # Active booking display
│   │   ├── AddScooterView.swift      # Multi-step scooter listing
│   │   ├── UserProfileView.swift     # User profile and settings
│   │   ├── PreviousBookingsView.swift # Rental history for renters
│   │   ├── OwnerPastRentalsView.swift # Rental history for owners
│   │   ├── BookingConfirmationView.swift # Owner booking approval
│   │   ├── ReturnScooterView.swift   # Scooter return process
│   │   ├── ScooterAvailabilitySheetView.swift # Availability scheduling
│   │   ├── SellerInfoView.swift      # Owner contact info
│   │   ├── MessagesView.swift        # In-app messaging (Coming Soon)
│   │   ├── SlideOutMenu.swift        # Side navigation menu
│   │   └── HelpAndSupportScreen.swift # Customer support
│   ├── Booking Views/
│   │   └── ScooterPickupView.swift   # Scooter check-in/out with photos
│   ├── Menu Views/
│   │   ├── ScootalPassView.swift     # Subscription management
│   │   ├── PaymentView.swift         # Add credits
│   │   ├── PromotionsView.swift      # Deals and promotions
│   │   ├── HowToRideView.swift       # Onboarding guide
│   │   ├── SafetyView.swift          # Safety tips
│   │   ├── HelpView.swift            # Help center
│   │   └── ComingSoon.swift          # Placeholder for features
│   ├── Helper Objects/
│   │   ├── User.swift                # User model
│   │   ├── Scooter.swift             # Scooter model
│   │   ├── Booking.swift             # Booking model
│   │   ├── Message.swift             # Message model
│   │   ├── DataManager.swift         # Firestore data fetching
│   │   ├── GradientButton.swift      # Custom button
│   │   └── TempTextField.swift       # Custom text field
│   └── Managers/
│       ├── BookingViewModel.swift    # Booking logic
│       ├── NavigationManager.swift   # Navigation state
│       └── ConfirmBookingManager.swift # Booking confirmation
├── Helpers/
│   ├── UIColor.swift                 # Color extensions
│   └── View+Extensions.swift         # SwiftUI extensions
├── Assets.xcassets/                  # App icons and colors
├── Scootal.entitlements              # App capabilities
└── firebase_functions/
    ├── firebase.json                 # Firebase config
    └── functions/
        ├── index.js                  # Cloud Functions
        └── package.json              # Node dependencies
```

## 🎨 Design System

### Colors
- **Primary**: `#0073e6` (Blue) - Main brand color
- **Secondary**: `#001f3f` (Navy) - Text and accents
- **Accent**: `#ff4500` (Orange-Red) - CTAs and highlights

### Typography
- **Titles**: SF Pro Display (Bold, Rounded)
- **Body**: SF Pro Text (Regular/Medium)
- **Captions**: SF Pro Text (Semibold)

### UI Components
- Rounded corners (10-20pt radius)
- Subtle shadows (opacity 0.1-0.2)
- Card-based layouts
- Bottom navigation bar
- Slide-out side menu

## 🧪 Testing

### Manual Testing Checklist
- [ ] Signup flow with email verification
- [ ] Login/logout functionality
- [ ] Browse and search scooters
- [ ] Filter by location and sort options
- [ ] Schedule ride with date/time picker
- [ ] View scooter details and owner info
- [ ] Complete booking with Stripe payment
- [ ] Active booking display and return
- [ ] List scooter with all steps
- [ ] Set availability schedule
- [ ] Approve/deny booking requests
- [ ] View earnings dashboard
- [ ] Subscribe to Scootal Pass
- [ ] Feature scooter with Apple Pay
- [ ] Report issues and customer support
- [ ] Push notifications

### Firebase Functions Testing
```bash
cd firebase_functions
npm run serve  # Start emulator
firebase functions:shell  # Test individual functions
```

## 🚀 Deployment

### App Store Submission
1. Archive app in Xcode
2. Upload to App Store Connect
3. Configure app metadata:
   - Screenshots (6.5" and 5.5" displays)
   - App description and keywords
   - Privacy policy URL
   - Support URL
4. Submit for review

### Firebase Deployment
```bash
firebase deploy  # Deploy all services
firebase deploy --only functions  # Deploy functions only
firebase deploy --only firestore:rules  # Deploy Firestore rules
firebase deploy --only storage:rules  # Deploy Storage rules
```

## 🐛 Known Issues & Roadmap

### Current Limitations
- Messaging feature not implemented (placeholder view exists)
- Push notifications configured but not fully tested
- Featured listings don't expire (manual reset required)
- School expansion limited to UC Irvine

### Planned Features
- Real-time chat between renters and owners
- GPS tracking during active rentals
- Damage claim processing with photo evidence
- Multi-school support with geofencing
- Ride history analytics and statistics
- Referral program with rewards
- In-app calendar integration

## 📄 License

This project is proprietary software developed for Scootal Inc. All rights reserved.

## 🤝 Contributing

This is a private project. For bug reports or feature requests, please contact the development team.

## 📞 Support

- **Email**: support@scootal.com
- **Website**: https://scootal.com
- **Twitter**: @ScootalApp

---

Built with ❤️ by the Scootal Team

