//
//  ManagerModel.swift
//  monopolytech
//
//  Created by Hugo Brun on 17/03/2025.
//

import Foundation

/// Modèle représentant un gestionnaire
struct Manager: Identifiable, Codable, Hashable {
    let id: String
    let nom: String
    let email: String
    let telephone: String
    let adresse: String
    let motdepasse: String?
    
    /// Gestionnaire exemple pour les prévisualisations et tests
    static let placeholder = Manager(
        id: "MNG1",
        nom: "Hugo Brun",
        email: "hugo.manager@example.com",
        telephone: "0123456789",
        adresse: "456 rue Manager",
        motdepasse: nil
    )
    
    /// Gestionnaire vide pour les états d'erreur ou d'initialisation
    static let empty = Manager(
        id: "NONE",
        nom: "No name found",
        email: "No email found",
        telephone: "No phone number",
        adresse: "No address found",
        motdepasse: nil
    )
    
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