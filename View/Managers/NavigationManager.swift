//
//  NavigationManager.swift
//  Eypma
//
//  Created by Sanjoy Datta on 2025-01-04.
//

import SwiftUI

class NavigationManager: ObservableObject {
    @Published var currentView: AppView = .home

    enum AppView {
        case home
        case confirmBooking(scooter: Scooter)
    }
}
