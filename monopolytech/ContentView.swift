//
//  ContentView.swift
//  monopolytech
//
//  Created by eugenio on 12/03/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var currentTab: Navbar.Tab = .home
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Contenu principal basé sur l'onglet sélectionné
                switch currentTab {
                case .home:
                    HomeView()
                        .padding(.bottom, 80)
                case .catalog:
                    CatalogView()
                        .padding(.bottom, 80)
                case .login:
                    Text("Login - Coming Soon")
                        .padding(.bottom, 80)
                }
                
                // Navbar en bas
                Navbar(currentTab: $currentTab)
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
