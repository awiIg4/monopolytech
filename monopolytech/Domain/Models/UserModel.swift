//
//  UserModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 17/03/2025.
//

import Foundation

struct User: Identifiable, Codable, Hashable {
    let id: String
    let nom: String
    let email: String
    let telephone: String
    let adresse: String?
    let type_utilisateur: String?
    
    // For preview and testing purposes
    static let placeholder = User(
        id: "USR1",
        nom: "Hugo Brun",
        email: "hugo.user@example.com",
        telephone: "0123456789",
        adresse: "321 rue User",
        type_utilisateur: "client"
    )
    
    // Empty state placeholders
    static let empty = User(
        id: "NONE",
        nom: "No name found",
        email: "No email found",
        telephone: "No phone number",
        adresse: "No address found",
        type_utilisateur: "No user type"
    )
    
    // Helper computed properties for empty state handling
    var displayName: String {
        return nom.isEmpty ? "No name found" : nom
    }
    
    var displayEmail: String {
        return email.isEmpty ? "No email found" : email
    }
    
    var displayPhone: String {
        return telephone.isEmpty ? "No phone number" : telephone
    }
    
    var displayAddress: String {
        return adresse ?? "No address found"
    }
    
    var displayType: String {
        return type_utilisateur ?? "No user type"
    }
} 