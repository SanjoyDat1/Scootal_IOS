# Scootal - Deployment Guide

This guide provides step-by-step instructions for deploying the Scootal app to production.

## 📋 Prerequisites

Before deploying, ensure you have:

- [ ] Xcode 15.0+ installed
- [ ] Valid Apple Developer account (Paid)
- [ ] Firebase project set up
- [ ] Stripe account with Connect enabled
- [ ] Domain name configured (for webhooks)
- [ ] App Store Connect app created
- [ ] All API keys and credentials ready

## 🔐 Environment Setup

### 1. Firebase Configuration

#### 1.1 Create Firebase Project
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize project
firebase init
```

Select:
- ✅ Firestore
- ✅ Storage
- ✅ Functions
- ✅ Hosting (optional)

#### 1.2 Configure Firestore
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules
```

**Firestore Rules** (`firestore.rules`):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /Users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Scooters collection
    match /Scooters/{scooterId} {
      allow read: if request.auth != null;
      allow create, update: if request.auth != null && request.auth.uid == resource.data.ownerID;
      allow delete: if request.auth != null && request.auth.uid == resource.data.ownerID;
    }
    
    // Bookings collection
    match /Bookings/{bookingId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.customerId || 
         request.auth.uid == resource.data.ownerId);
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
        (request.auth.uid == resource.data.customerId || 
         request.auth.uid == resource.data.ownerId);
    }
    
    // Providers collection (Stripe Connect)
    match /providers/{providerId} {
      allow read, write: if request.auth != null && request.auth.uid == providerId;
    }
    
    // Subscriptions collection
    match /subscriptions/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // School requests (public write)
    match /schoolRequests/{requestId} {
      allow create: if true;
      allow read: if request.auth != null;
    }
  }
}
```

#### 1.3 Configure Storage
```bash
# Deploy Storage rules
firebase deploy --only storage:rules
```

**Storage Rules** (`storage.rules`):
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User photos (ID and face)
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Scooter images
    match /scooter_images/{imageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Scooter check-in/out photos
    match /scooter_photos/{photoId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

#### 1.4 Configure Authentication
In Firebase Console:
1. Go to Authentication → Sign-in method
2. Enable Email/Password
3. Configure email templates:
   - Email verification template
   - Password reset template
4. Add authorized domains for deep links

### 2. Stripe Configuration

#### 2.1 Create Stripe Account
1. Sign up at https://stripe.com
2. Complete business verification
3. Enable Stripe Connect

#### 2.2 Configure Connect Settings
1. Go to Connect → Settings
2. Set Platform settings:
   - Platform name: "Scootal"
   - Support email: support@scootal.com
   - Branding: Upload logo and colors
3. Configure Express accounts:
   - Enable automatic payouts
   - Set payout schedule: Daily
   - Required capabilities: `card_payments`, `transfers`

#### 2.3 Set API Keys
```bash
# Get publishable key from Stripe Dashboard
# Test: pk_test_...
# Live: pk_live_...

# Update in BookingView.swift and EypmaApp.swift
StripeAPI.defaultPublishableKey = "pk_live_YOUR_KEY"
```

#### 2.4 Configure Webhooks
1. Go to Developers → Webhooks
2. Add endpoint: `https://us-central1-YOUR_PROJECT.cloudfunctions.net/stripeWebhook`
3. Select events:
   - `account.updated`
   - `payment_intent.succeeded`
4. Copy signing secret: `whsec_...`

#### 2.5 Set Firebase Functions Config
```bash
# Set Stripe secret key
firebase functions:config:set stripe.secret_key="sk_live_YOUR_KEY"

# Set webhook secret
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_SECRET"

# Deploy functions
firebase deploy --only functions
```

### 3. Apple Developer Setup

#### 3.1 Create App Identifier
1. Go to Certificates, Identifiers & Profiles
2. Create new App ID:
   - Description: Scootal
   - Bundle ID: com.eympa.Scootal (or your bundle ID)
3. Enable capabilities:
   - ✅ Push Notifications
   - ✅ In-App Purchase
   - ✅ Apple Pay

#### 3.2 Configure Apple Pay
1. Create Merchant ID: `merchant.com.Scootal.scootal`
2. Generate payment processing certificate
3. Upload to Stripe Dashboard (for Apple Pay)

#### 3.3 Configure Push Notifications
1. Create APNs Key:
   - Go to Keys → Create new key
   - Enable Apple Push Notifications service
   - Download key file (.p8)
2. Upload to Firebase Console:
   - Project Settings → Cloud Messaging
   - Upload APNs Authentication Key
   - Enter Key ID and Team ID

### 4. In-App Purchases (StoreKit)

#### 4.1 Create Products in App Store Connect
1. Go to App Store Connect → My Apps → Your App
2. Go to In-App Purchases
3. Create Auto-Renewable Subscriptions:

**Monthly Subscription:**
- Product ID: `com.eympa.Eympa.scootalpass.monthly`
- Reference Name: Scootal Pass Monthly
- Subscription Group: Scootal Pass
- Subscription Duration: 1 Month
- Price: $2.99 (USD)

**Annual Subscription:**
- Product ID: `com.eympa.Eympa.scootalpass.annual`
- Reference Name: Scootal Pass Annual
- Subscription Group: Scootal Pass
- Subscription Duration: 1 Year
- Price: $29.99 (USD)

#### 4.2 Configure Subscription Details
- Subscription Name: Scootal Pass
- Description: No unlock fees on all rides
- Benefits:
  - Priority access to scooters
  - No unlock fee ($1 savings per ride)
  - Bring a friend for free once a month

#### 4.3 Set Up Introductory Offers (Optional)
- Free trial: 7 days
- Pay as you go: First month $0.99

### 5. Cloud Functions Deployment

#### 5.1 Install Dependencies
```bash
cd firebase_functions/functions
npm install
```

#### 5.2 Test Locally
```bash
# Start emulators
firebase emulators:start --only functions

# Test createPaymentIntent
curl http://localhost:5001/YOUR_PROJECT/us-central1/createPaymentIntent \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000, "providerId": "test123", "scooterId": "scooter123"}'
```

#### 5.3 Deploy to Production
```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:createPaymentIntent
```

#### 5.4 Verify Deployment
```bash
# Check function logs
firebase functions:log

# Test with curl
curl https://us-central1-YOUR_PROJECT.cloudfunctions.net/createPaymentIntent \
  -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000, "providerId": "test123", "scooterId": "scooter123"}'
```

## 📱 iOS App Deployment

### 1. Update Configuration

#### 1.1 Update Bundle Identifier
- Open Xcode project
- Select target → General
- Update Bundle Identifier to match App Store Connect

#### 1.2 Update Version and Build Number
- Version: 1.0.0 (user-facing)
- Build: 1 (increment for each upload)

#### 1.3 Configure Signing
- Select target → Signing & Capabilities
- Team: Your Apple Developer Team
- Signing Certificate: Distribution
- Provisioning Profile: App Store

#### 1.4 Update API Keys
Replace all test keys with production keys:

**Firebase:**
- Update `GoogleService-Info.plist`

**Stripe:**
```swift
// In BookingView.swift and EypmaApp.swift
StripeAPI.defaultPublishableKey = "pk_live_51QeTUuIWrE69S61q7W01X8ZQBk5fE92SFd5ociPzhp1ifM7ddoSJGrQJ9dVH0mXcmMH1L8vyNtJmx38kou01WuIs00hdlsuXF7"
```

### 2. Create Archive

```bash
# 1. Clean build folder
Product → Clean Build Folder (Cmd + Shift + K)

# 2. Select "Any iOS Device" as destination

# 3. Archive
Product → Archive (Cmd + B)
```

### 3. Upload to App Store Connect

#### 3.1 Validate Archive
1. Open Organizer (Window → Organizer)
2. Select latest archive
3. Click "Validate App"
4. Fix any issues

#### 3.2 Upload Archive
1. Click "Distribute App"
2. Select "App Store Connect"
3. Upload to App Store
4. Wait for processing (~10-30 minutes)

### 4. Configure App Store Listing

#### 4.1 App Information
- Name: Scootal
- Subtitle: Rent Scooters on Campus
- Category: Travel
- Content Rights: Yes (you own or have rights)

#### 4.2 Pricing and Availability
- Price: Free
- Availability: United States
- Pre-order: No

#### 4.3 App Privacy
Configure privacy details:
- Email addresses (for authentication)
- Phone numbers (for contact)
- Photos (for ID verification and scooter images)
- Location (for scooter pickup)
- Payment info (for bookings)

#### 4.4 Screenshots
Required sizes:
- 6.5" Display (iPhone 14 Pro Max): 1290 x 2796
- 5.5" Display (iPhone 8 Plus): 1242 x 2208

Screens to capture:
1. Scooter browsing
2. Scooter details
3. Booking screen
4. User profile
5. Scootal Pass

#### 4.5 App Preview Videos (Optional)
- Length: 15-30 seconds
- Show key features: Browse, Book, Ride, Return

#### 4.6 Description
```
Scootal - Rent Electric Scooters from Students

Need a ride around campus? Rent a scooter from a fellow student in minutes!

HOW IT WORKS:
• Browse available scooters near you
• Book for 6 hours or 24 hours
• Meet the owner and ride away
• Return and pay seamlessly

FOR RENTERS:
✓ Affordable hourly and daily rates
✓ Schedule rides up to 7 weeks in advance
✓ Safety guidelines and support
✓ Scootal Pass: Subscribe for no unlock fees

FOR OWNERS:
✓ List your scooter and earn passive income
✓ Set your own prices and schedule
✓ Optional protection plans
✓ Direct deposits to your bank

SAFETY FIRST:
• Verified student accounts
• ID verification required
• Damage reporting system
• 24/7 customer support

Download Scootal and join the campus mobility revolution!
```

#### 4.7 Keywords
```
scooter, rental, student, campus, transportation, ride, electric, sharing, peer-to-peer, mobility
```

#### 4.8 Support URL
```
https://scootal.com/support
```

#### 4.9 Privacy Policy URL
```
https://scootal.com/privacy
```

### 5. Submit for Review

#### 5.1 Review Information
- Sign-in required: Yes
- Demo account:
  - Email: demo@uci.edu
  - Password: Demo123456!
- Notes: Provide test instructions

#### 5.2 App Review Notes
```
TESTING INSTRUCTIONS:

1. SIGNUP (Optional - use demo account):
   - Email must be @uci.edu
   - Upload any ID and face photo
   - Verify email via link

2. BROWSING:
   - View scooters at "Aldrich Park"
   - Filter and sort available scooters

3. BOOKING:
   - Select any scooter
   - Choose 6-hour rental
   - Use test card: 4242 4242 4242 4242
   - Expiry: Any future date
   - CVC: Any 3 digits

4. LISTING (Optional):
   - Go to Profile → Add Scooter
   - Upload scooter photo
   - Set availability

Please contact support@scootal.com with any questions.
```

#### 5.3 Submit
1. Click "Add for Review"
2. Click "Submit for Review"
3. Wait for Apple's response (1-7 days)

## 🚀 Post-Deployment

### 1. Monitor App Performance

#### 1.1 App Store Connect Analytics
- Impressions and downloads
- Conversion rate
- Crashes and feedback

#### 1.2 Firebase Analytics
```bash
# View analytics in Firebase Console
firebase analytics:dashboard
```

#### 1.3 Stripe Dashboard
- Monitor payments and transfers
- Track connected account onboarding
- Review disputes and refunds

### 2. Set Up Monitoring

#### 2.1 Crashlytics
```swift
// Already configured in EypmaApp.swift
import FirebaseCrashlytics

// Force a crash for testing (remove after verification)
Crashlytics.crashlytics().record(error: NSError(domain: "test", code: 0))
```

#### 2.2 Performance Monitoring
```swift
import FirebasePerformance

// Trace key operations
let trace = Performance.startTrace(name: "scooter_booking")
// ... perform booking
trace?.stop()
```

#### 2.3 Cloud Functions Monitoring
```bash
# View function logs
firebase functions:log

# Set up alerts
# Go to Firebase Console → Functions → Logs
# Create alert for errors
```

### 3. Update DNS Records

#### 3.1 Configure Domain
Point your domain to Firebase Hosting (if using):
```bash
# Add custom domain
firebase hosting:channel:deploy production --only hosting

# Configure DNS
# A record: 151.101.1.195
# A record: 151.101.65.195
```

#### 3.2 SSL Certificate
Firebase automatically provisions SSL certificates for custom domains.

### 4. Marketing & Launch

#### 4.1 App Store Optimization (ASO)
- Optimize keywords based on performance
- A/B test screenshots and descriptions
- Encourage user reviews

#### 4.2 Social Media
- Announce on Twitter, Instagram, Facebook
- Create demo videos
- Partner with campus influencers

#### 4.3 On-Campus Promotion
- Flyers and posters
- Student organization partnerships
- Launch event or promotion

## 🔄 Continuous Deployment

### 1. Version Updates

#### 1.1 Increment Version
```bash
# Update version in Xcode
# Version: 1.0.0 → 1.0.1 (bug fix)
# Version: 1.0.0 → 1.1.0 (new features)
# Version: 1.0.0 → 2.0.0 (major changes)
```

#### 1.2 Update Cloud Functions
```bash
# Test changes locally
firebase emulators:start --only functions

# Deploy updates
firebase deploy --only functions
```

#### 1.3 Submit Update
Follow same process as initial submission.

### 2. Hotfix Deployment

#### 2.1 Critical Bug Fix
```bash
# 1. Fix bug in code
# 2. Increment build number only
# 3. Archive and upload
# 4. Submit as "Bug Fix" in review notes
```

#### 2.2 Expedited Review
Request expedited review in App Store Connect if critical.

## 🆘 Troubleshooting

### Common Issues

#### 1. Firebase Connection Failed
```swift
// Verify GoogleService-Info.plist is in project
// Check bundle identifier matches Firebase project
// Ensure Firebase is initialized in AppDelegate
```

#### 2. Stripe Payment Fails
```bash
# Verify API keys are correct (not test keys)
# Check webhook endpoint is accessible
# Review Stripe dashboard for error messages
```

#### 3. StoreKit Products Not Loading
```swift
// Ensure product IDs match App Store Connect exactly
// Verify app is signed with correct provisioning profile
// Wait 24 hours after creating products
```

#### 4. Push Notifications Not Working
```bash
# Verify APNs certificate is uploaded to Firebase
# Check device token is registered
# Test in production environment (not simulator)
```

## 📝 Checklist

### Pre-Deployment
- [ ] All features tested on physical device
- [ ] Production API keys configured
- [ ] Firebase security rules updated
- [ ] Stripe webhooks configured
- [ ] In-app purchases created
- [ ] App Store listing prepared
- [ ] Screenshots and videos ready
- [ ] Privacy policy and terms updated

### Deployment
- [ ] Archive created successfully
- [ ] App validated without errors
- [ ] Uploaded to App Store Connect
- [ ] TestFlight tested (optional)
- [ ] Submit for review
- [ ] Cloud Functions deployed
- [ ] Database indexes created

### Post-Deployment
- [ ] Monitor crash reports
- [ ] Check payment processing
- [ ] Verify push notifications
- [ ] Test user flows
- [ ] Respond to user feedback
- [ ] Track analytics

## 🎉 Launch Day

1. **Morning of Launch:**
   - Monitor App Store for approval
   - Prepare social media posts
   - Alert support team

2. **Upon Approval:**
   - Post on social media
   - Send email to beta testers
   - Update website

3. **First Week:**
   - Monitor analytics daily
   - Respond to reviews quickly
   - Fix critical bugs immediately
   - Gather user feedback

Good luck with your deployment! 🚀

