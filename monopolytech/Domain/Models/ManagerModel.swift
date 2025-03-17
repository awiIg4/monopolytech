//
//  ManagerModel.swift
//  monopolytech
//
//  Created by hugo on 17/03/2024.
//

import Foundation

struct Manager: Identifiable, Codable, Hashable {
    let id: String
    let nom: String
    let email: String
    let telephone: String
    let adresse: String
    let motdepasse: String?
    
    // For preview and testing purposes
    static let placeholder = Manager(
        id: "MNG1",
        nom: "Hugo Brun",
        email: "hugo.manager@example.com",
        telephone: "0123456789",
        adresse: "456 rue Manager",
        motdepasse: nil
    )
    
    // Empty state placeholders
    static let empty = Manager(
        id: "NONE",
        nom: "No name found",
        email: "No email found",
        telephone: "No phone number",
        adresse: "No address found",
        motdepasse: nil
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
        return adresse.isEmpty ? "No address found" : adresse
    }
} 