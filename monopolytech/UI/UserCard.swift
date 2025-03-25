//
//  UserCard.swift
//  monopolytech
//
//  Created by Hugo Brun on 17/03/2025.
//

import SwiftUI

/// Protocole définissant les propriétés d'affichage communes à tous les utilisateurs
protocol UserDisplayable {
    var displayName: String { get }
    var displayEmail: String { get }
    var displayPhone: String { get }
    var displayAddress: String { get }
}

// Conformité des modèles au protocole UserDisplayable
extension Buyer: UserDisplayable {}
extension Seller: UserDisplayable {}
extension Manager: UserDisplayable {}

/// Carte réutilisable pour afficher les informations d'un utilisateur
struct UserCard<T: UserDisplayable>: View {
    let user: T
    var onTap: ((T) -> Void)? = nil
    
    var body: some View {
        Button(action: {
            onTap?(user)
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(user.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "envelope")
                    Text(user.displayEmail)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "phone")
                    Text(user.displayPhone)
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "location")
                    Text(user.displayAddress)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UserCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            UserCard(user: Buyer.placeholder)
                .padding()
            
            UserCard(user: Seller.placeholder)
                .padding()
            
            UserCard(user: Manager.placeholder)
                .padding()
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                UserCard(user: Buyer.placeholder)
                UserCard(user: Seller.placeholder)
                UserCard(user: Manager.placeholder)
                UserCard(user: Buyer.placeholder)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}

