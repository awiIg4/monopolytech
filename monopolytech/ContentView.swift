//
//  ContentView.swift
//  monopolytech
//
//  Created by eugenio on 12/03/2025.
//

import SwiftUI

/// Définition des onglets de navigation
enum Tab {
    case home
    case catalog
    case manage
    case login
}

/// Vue principale de l'application
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
                
                // Navbar
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

private func setupActions() {
}
