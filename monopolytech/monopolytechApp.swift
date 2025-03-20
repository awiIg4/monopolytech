//
//  monopolytechApp.swift
//  monopolytech
//
//  Created by eugenio on 12/03/2025.
//

import SwiftUI

@main
struct monopolytechApp: App {
    // Add state object to hold environment-wide auth service
    @StateObject private var authService = AuthService.shared
    
    init() {
        // Set up notification observer for token expiration
        setupNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .toastMessage() // Add the toast message modifier here
        }
    }
    
    private func setupNotifications() {
        // Add observer for token expiration
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TokenExpired"),
            object: nil,
            queue: .main
        ) { _ in
            // Show notification to user when token expires
            NotificationService.shared.showInfo("Votre session a expiré. Veuillez vous reconnecter.")
            
            // No need to handle logout here as AuthService already does it
        }
    }
}
