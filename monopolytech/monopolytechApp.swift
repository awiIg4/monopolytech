//
//  monopolytechApp.swift
//  monopolytech
//
//  Created by eugenio on 12/03/2025.
//

import SwiftUI

/// Point d'entrée principal de l'application
@main
struct monopolytechApp: App {
    @StateObject private var authService = AuthService.shared
    
    init() {
        setupNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .toastMessage()
        }
    }
    
    /// Configure les notifications pour l'expiration du token
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TokenExpired"),
            object: nil,
            queue: .main
        ) { _ in
            NotificationService.shared.showInfo("Votre session a expiré. Veuillez vous reconnecter.")
        }
    }
}
