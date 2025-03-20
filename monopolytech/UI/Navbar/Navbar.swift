//
//  Navbar.swift
//  monopolytech
//
//  Created by Hugo Brun on 19/03/2025.
//

import SwiftUI

struct Navbar: View {
    @Binding var currentTab: Tab
    
    enum Tab {
        case login
        case home
        case catalog
    }
    
    var body: some View {
        HStack {
            // Bouton Login
            TabButton(
                icon: "person.fill",
                title: "Login",
                isSelected: currentTab == .login,
                action: { currentTab = .login }
            )
            
            Spacer()
            
            // Bouton Home
            TabButton(
                icon: "house.fill",
                title: "Home",
                isSelected: currentTab == .home,
                action: { currentTab = .home }
            )
            
            Spacer()
            
            // Bouton Catalogue
            TabButton(
                icon: "gamecontroller.fill",
                title: "Catalogue",
                isSelected: currentTab == .catalog,
                action: { currentTab = .catalog }
            )
        }
        .padding(.horizontal, 25)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.3), radius: 5, y: -5)
        )
    }
}

struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .blue : .gray)
        }
    }
}

#Preview {
    Navbar(currentTab: .constant(.home))
}

