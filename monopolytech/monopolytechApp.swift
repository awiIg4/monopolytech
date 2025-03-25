//
//  monopolytechApp.swift
//  monopolytech
//
//  Created by eugenio on 12/03/2025.
//

import SwiftUI

@main
struct monopolytechApp: App {
    /// Service d'authentification partagé dans l'application
    @StateObject private var authService = AuthService.shared
    
    init() {
        // Configuration des notifications
        setupNotifications()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .toastMessage() // Ajout du modificateur pour les messages toast
        }
    }
    
    /// Configure les observateurs de notifications
    private func setupNotifications() {
        // Observateur pour l'expiration du token
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TokenExpired"),
            object: nil,
            queue: .main
        ) { _ in
            // Affiche une notification lorsque le token expire
            NotificationService.shared.showInfo("Votre session a expiré. Veuillez vous reconnecter.")
        }
    }
}
