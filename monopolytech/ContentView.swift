//
//  ContentView.swift
//  monopolytech
//
//  Created by eugenio on 12/03/2025.
//

import SwiftUI

/// Définition des onglets disponibles dans l'application
enum Tab {
    case home
    case catalog
    case manage
    case login
}

struct ContentView: View {
    /// Service d'authentification pour gérer l'état de connexion
    @StateObject private var authService = AuthService.shared
    /// Onglet actuellement sélectionné
    @State private var currentTab: Navbar.Tab = .home
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Affichage du contenu en fonction de l'onglet sélectionné
                Group {
                    switch currentTab {
                    case .home:
                        HomeView()
                    case .catalog:
                        CatalogView()
                    case .manage where authService.isAuthenticated:
                        ManageView()
                    case .login, .manage:
                        LoginView()
                    }
                }
                .padding(.bottom, 50)
                
                // Barre de navigation personnalisée
                VStack(spacing: 0) {
                    Divider()
                    Navbar(currentTab: $currentTab)
                }
                .background(Color.white)
            }
            .ignoresSafeArea(edges: .bottom)
            .onChange(of: authService.isAuthenticated) { isAuthenticated in
                // Changement automatique d'onglet lors de la connexion/déconnexion
                if isAuthenticated {
                    currentTab = .manage
                } else {
                    currentTab = .home
                }
            }
        }
        .environmentObject(authService)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

private func setupActions() {
    // Add navigation to game deposit
    // This will be called when the user taps on the "Deposit Game" item
}
