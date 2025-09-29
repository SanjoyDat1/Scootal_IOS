# Scootal - Quick Start Guide

Get the Scootal app running locally in under 30 minutes!

## 🚀 Prerequisites

- macOS with Xcode 15.0+
- Apple Developer account (free tier OK for testing)
- Node.js 18+ (for Firebase Functions)
- Git

## 📦 Step 1: Clone & Install

```bash
# Clone the repository (if applicable)
cd /Users/sanjoydatta/Desktop/Eympa_App/Scootal

# Install CocoaPods dependencies (if using)
pod install

# Or use Swift Package Manager (already configured)
```

## 🔥 Step 2: Firebase Setup

### 2.1 Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click "Add project"
3. Enter project name: "scootal-dev"
4. Enable Google Analytics (optional)
5. Create project

### 2.2 Add iOS App
1. Click "Add app" → iOS
2. Enter Bundle ID: `com.eympa.Scootal` (or your bundle ID)
3. Download `GoogleService-Info.plist`
4. Add to Xcode project (drag into project navigator)
5. Ensure "Copy items if needed" is checked

### 2.3 Enable Authentication
1. Go to Authentication → Sign-in method
2. Enable "Email/Password"
3. Click "Save"

### 2.4 Create Firestore Database
1. Go to Firestore Database
2. Click "Create database"
3. Start in "test mode" (we'll add rules later)
4. Select region: `us-central`
5. Click "Enable"

### 2.5 Create Storage Bucket
1. Go to Storage
2. Click "Get started"
3. Start in "test mode"
4. Use default location
5. Click "Done"

### 2.6 Test Firebase Connection
```bash
# Build and run in Xcode
# If Firebase initializes, you'll see: "Firebase initialized successfully"
```

## 💳 Step 3: Stripe Setup (For Testing)

### 3.1 Create Stripe Account
1. Go to https://stripe.com
2. Create account (can use test mode)
3. Go to Dashboard

### 3.2 Get Test API Keys
1. Go to Developers → API keys
2. Copy "Publishable key" (starts with `pk_test_`)
3. Update in `BookingView.swift`:
   ```swift
   StripeAPI.defaultPublishableKey = "pk_test_YOUR_KEY"
   ```
4. Update in `EypmaApp.swift`:
   ```swift
   StripeAPI.defaultPublishableKey = "pk_test_YOUR_KEY"
   ```

### 3.3 Skip Connect Setup (For Now)
- Payment features will use test mode
- Connect setup needed for production only

## 🍎 Step 4: Apple Configuration

### 4.1 Configure Bundle Identifier
1. Open project in Xcode
2. Select target → General
3. Change Bundle Identifier to your own (e.g., `com.yourname.scootal`)
4. Select your development team

### 4.2 Disable In-App Purchases (Testing Only)
Temporarily disable StoreKit features:
1. Comment out StoreKit code in `ScootalPassView.swift`:
   ```swift
   // Temporarily disable for local testing
   // storeKitManager.fetchProducts(...)
   ```

### 4.3 Disable Apple Pay (Testing Only)
Comment out Apple Pay in `PaymentView.swift`:
```swift
// Temporarily disable for local testing
// if PKPaymentAuthorizationController.canMakePayments() { ... }
```

## ▶️ Step 5: Build & Run

### 5.1 Select Target
1. Open Xcode
2. Select target device/simulator (iPhone 15 Pro recommended)
3. Press `Cmd + B` to build
4. Press `Cmd + R` to run

### 5.2 Create Test Account
1. App launches → Signup screen
2. Enter test data:
   - First Name: Test
   - Last Name: User
   - Email: test@uci.edu
   - Phone: (949) 555-0100
   - Password: Test123456!
3. Upload any photo for ID and face
4. Complete signup

### 5.3 Verify Email
1. Check Firebase Console → Authentication
2. Find user, click "..." → Send verification email
3. Or use this workaround:
   ```swift
   // In ContentView.swift, temporarily skip email verification:
   if user.isEmailVerified || true { // <- Add || true
       isUserLoggedIn = true
   }
   ```

### 5.4 Test Core Features
- ✅ Browse scooters (none will show yet - need to add test data)
- ✅ Navigate to Profile
- ✅ Try to add a scooter

## 📊 Step 6: Add Test Data

### 6.1 Create Test Scooter in Firestore
1. Go to Firebase Console → Firestore
2. Click "Start collection"
3. Collection ID: `Scooters`
4. Add document with auto-ID:
   ```json
   {
     "id": "test-scooter-1",
     "scooterName": "Test Scooter",
     "brand": "Xiaomi",
     "modelName": "Mi Electric",
     "description": "Great scooter for testing",
     "imageURL": "https://via.placeholder.com/400",
     "location": "Aldrich Park",
     "sixHourPrice": 6.00,
     "fullDayPrice": 10.00,
     "topSpeed": 15,
     "range": 20,
     "isElectric": true,
     "isAvailable": true,
     "isBooked": false,
     "activeBooking": false,
     "isFeatured": false,
     "ownerID": "YOUR_USER_UID",
     "damages": "None",
     "restrictions": "None",
     "specialNotes": "Test scooter",
     "availability": {
       "monday": {
         "isAvailable": true,
         "startTime": "09:00",
         "endTime": "17:00"
       }
     }
   }
   ```
5. Replace `YOUR_USER_UID` with your Firebase Auth UID

### 6.2 Refresh App
1. Pull down to refresh in ScooterListView
2. Test scooter should appear

### 6.3 Test Booking Flow
1. Tap test scooter
2. View details
3. Try to book (payment will fail without Stripe setup - that's OK)

## 🧪 Step 7: Local Cloud Functions (Optional)

### 7.1 Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### 7.2 Initialize Functions
```bash
cd firebase_functions/functions
npm install
```

### 7.3 Run Emulator
```bash
cd ..
firebase emulators:start --only functions
```

### 7.4 Test Function
```bash
# In another terminal
curl http://localhost:5001/YOUR_PROJECT_ID/us-central1/createPaymentIntent \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000, "providerId": "test", "scooterId": "test"}'
```

## ✅ Verification Checklist

- [ ] App builds without errors
- [ ] Firebase initialized successfully
- [ ] Can create account and login
- [ ] Can view test scooter
- [ ] Can navigate between screens
- [ ] Profile loads correctly
- [ ] Can add scooter (form works)

## 🐛 Troubleshooting

### Issue: "Firebase app not initialized"
**Solution**: 
1. Verify `GoogleService-Info.plist` is in project
2. Check bundle identifier matches Firebase project
3. Clean build folder: `Cmd + Shift + K`

### Issue: "No scooters showing"
**Solution**: 
1. Add test data to Firestore (see Step 6.1)
2. Check `ownerID` matches your user UID
3. Pull down to refresh

### Issue: "Stripe payment fails"
**Solution**: 
1. Use test card: 4242 4242 4242 4242
2. Any future expiry date
3. Any 3-digit CVC
4. If still fails, check API key in code

### Issue: "Build errors"
**Solution**: 
1. Update pod dependencies: `pod update`
2. Clean build folder: `Cmd + Shift + K`
3. Delete derived data: `~/Library/Developer/Xcode/DerivedData`
4. Restart Xcode

### Issue: "Email verification required"
**Solution**: 
1. Go to Firebase Console → Authentication
2. Find user, send verification email
3. Or bypass check (see Step 5.3)

## 🎯 Next Steps

Now that you have the app running:

1. **Explore Features**:
   - Add your own scooter
   - Set availability
   - Test booking flow

2. **Read Documentation**:
   - `README.md` - Full feature guide
   - `DEPLOYMENT.md` - Production setup
   - `PROJECT_SUMMARY.md` - Technical overview

3. **Customize**:
   - Update branding colors
   - Add your own locations
   - Modify pricing logic

4. **Deploy**:
   - Follow `DEPLOYMENT.md` for production setup

## 🆘 Getting Help

- **Check docs**: README.md, DEPLOYMENT.md
- **Firebase Console**: Check logs and errors
- **Xcode Console**: View runtime errors
- **Common Issues**: See Troubleshooting section above

## 🎉 You're Ready!

The app should now be running locally. You can:
- Browse scooters
- Test the booking flow
- Add your own scooters
- Explore all features

For production deployment, see `DEPLOYMENT.md`.

Happy coding! 🚀

