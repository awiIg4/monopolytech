//
//  ContentView.swift
//  monopolytech
//
//  Created by eugenio on 12/03/2025.
//

import SwiftUI

// Définition de l'énumération Tab
enum Tab {
    case home
    case catalog
    case manage
    case login
}

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    @State private var currentTab: Navbar.Tab = .home
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Contenu principal basé sur l'onglet sélectionné
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
                
                // Navbar personnalisée
                VStack(spacing: 0) {
                    Divider()
                    Navbar(currentTab: $currentTab)
                }
                .background(Color.white)
            }
            .ignoresSafeArea(edges: .bottom)
            .onChange(of: authService.isAuthenticated) { isAuthenticated in
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

// In ManageViewModel.swift, update the setupActions method

private func setupActions() {
    // Add navigation to game deposit
    // This will be called when the user taps on the "Deposit Game" item
}
