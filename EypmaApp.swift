//
//  EypmaApp.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2024-12-15.
//
import Firebase
import FirebaseAuth
import FirebaseCore
import UIKit
import SwiftUI

@main
struct EypmaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .onOpenURL { url in
                        print("Received URL: \(url)")
                        let result = Auth.auth().canHandle(url)
                        print(result)
                    }
            }
        }
    }
}

import UIKit
import FirebaseCore
import FirebaseMessaging
import StripePaymentSheet
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Initialize Stripe
        StripeAPI.defaultPublishableKey = "pk_live_51QeTUuIWrE69S61q7W01X8ZQBk5fE92SFd5ociPzhp1ifM7ddoSJGrQJ9dVH0mXcmMH1L8vyNtJmx38kou01WuIs00hdlsuXF7"
        
        // Set up Firebase Messaging
        Messaging.messaging().delegate = self
        
        // Register for push notifications
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error.localizedDescription)")
                return
            }
            if granted {
                print("Push notification permissions granted")
            }
        }
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // Handle APNs token registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Successfully registered for remote notifications with APNs token")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // Firebase Messaging delegate method for FCM token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken {
            print("FCM Token received: \(fcmToken)")
            // Optionally store the token in Firestore for sending notifications
            if let userId = Auth.auth().currentUser?.uid {
                let db = Firestore.firestore()
                db.collection("Users").document(userId).setData(["fcmToken": fcmToken], merge: true)
            }
        } else {
            print("No FCM token received")
        }
    }
    
    // Handle foreground notifications
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }
}
